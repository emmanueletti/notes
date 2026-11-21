class CurrencyMismatch < StandardError; end

Money = Data.define(:cents, :currency) do
  include Comparable

  def self.zero(currency) = new(cents: 0, currency:)

  def +(other) = with(cents: cents + same_currency(other).cents)
  def -(other) = with(cents: cents - same_currency(other).cents)
  def *(quantity) = with(cents: cents * quantity)
  def <=>(other) = cents <=> same_currency(other).cents
  def negative? = cents.negative?

  # The only place money is rounded. Banker's rounding avoids a bias toward rounding up.
  def percent(rate) = with(cents: (cents * rate / 100r).round(half: :even))

  def to_s = format("%s %.2f", currency, cents / 100.0)

  private

  def same_currency(other)
    raise CurrencyMismatch, "#{currency} vs #{other.currency}" unless other.currency == currency

    other
  end
end

LineItem = Data.define(:sku, :unit_price, :quantity) do
  def subtotal = unit_price * quantity
end

Adjustment = Data.define(:label, :amount)

# Stacking order is fixed by priority, not by the order discounts were added:
# item deals first, then percentages, then fixed amounts.
class BuyXGetY
  PRIORITY = 1

  def initialize(sku:, buy:, get:)
    @sku = sku
    @buy = buy
    @get = get
  end

  def priority = PRIORITY

  def adjustment(lines, _running_total)
    line = lines.find { _1.sku == @sku }
    return unless line

    free_units = line.quantity / (@buy + @get) * @get
    return if free_units.zero?

    Adjustment.new(label: "Buy #{@buy} get #{@get} on #{@sku}", amount: line.unit_price * free_units)
  end
end

class PercentOff
  PRIORITY = 2

  def initialize(rate:)
    raise ArgumentError, "rate must be 0-100" unless rate.between?(0, 100)

    @rate = rate
  end

  def priority = PRIORITY

  def adjustment(_lines, running_total)
    Adjustment.new(label: "#{@rate}% off", amount: running_total.percent(@rate))
  end
end

class FixedOff
  PRIORITY = 3

  def initialize(amount:)
    @amount = amount
  end

  def priority = PRIORITY

  def adjustment(_lines, running_total)
    Adjustment.new(label: "#{@amount} off", amount: [@amount, running_total].min)
  end
end

Totals = Data.define(:subtotal, :adjustments, :tax, :total) do
  def discount = adjustments.map(&:amount).reduce(Money.zero(subtotal.currency), :+)
end

class Cart
  def initialize(currency:, tax_rate: 0)
    @currency = currency
    @tax_rate = tax_rate
    @lines = {}
    @discounts = []
  end

  def add(sku, unit_price, quantity = 1)
    raise ArgumentError, "quantity must be positive" unless quantity.positive?
    raise CurrencyMismatch, "cart is #{@currency}" unless unit_price.currency == @currency

    existing = @lines[sku]
    raise ArgumentError, "#{sku} already has a different price" if existing && existing.unit_price != unit_price

    @lines[sku] = LineItem.new(sku:, unit_price:, quantity: (existing&.quantity || 0) + quantity)
  end

  def remove(sku) = @lines.delete(sku)

  def apply(discount) = @discounts << discount

  def lines = @lines.values

  def totals
    subtotal = lines.map(&:subtotal).reduce(Money.zero(@currency), :+)
    running = subtotal
    adjustments = @discounts.sort_by(&:priority).filter_map do |discount|
      discount.adjustment(lines, running)&.tap { running -= _1.amount }
    end
    tax = running.percent(@tax_rate)
    Totals.new(subtotal:, adjustments:, tax:, total: running + tax)
  end
end

if $PROGRAM_NAME == __FILE__
  require "minitest/autorun"

  class CartTest < Minitest::Test
    def cad(cents) = Money.new(cents:, currency: "CAD")

    def setup
      @cart = Cart.new(currency: "CAD")
    end

    def test_line_items_and_subtotal
      @cart.add("mug", cad(1500), 2)
      @cart.add("tee", cad(2500))
      @cart.add("mug", cad(1500))
      assert_equal 3, @cart.lines.find { _1.sku == "mug" }.quantity
      assert_equal cad(7000), @cart.totals.total
    end

    def test_empty_cart
      assert_equal cad(0), @cart.totals.total
    end

    def test_percent_off
      @cart.add("tee", cad(10_000))
      @cart.apply(PercentOff.new(rate: 10))
      assert_equal cad(9000), @cart.totals.total
    end

    def test_fixed_off_never_goes_below_zero
      @cart.add("sticker", cad(300))
      @cart.apply(FixedOff.new(amount: cad(500)))
      assert_equal cad(0), @cart.totals.total
    end

    def test_buy_two_get_one_free
      @cart.add("mug", cad(1000), 7)
      @cart.apply(BuyXGetY.new(sku: "mug", buy: 2, get: 1))
      assert_equal cad(5000), @cart.totals.total
    end

    def test_stacking_order_ignores_apply_order
      @cart.add("tee", cad(10_000))
      @cart.apply(FixedOff.new(amount: cad(500)))
      @cart.apply(PercentOff.new(rate: 10))
      totals = @cart.totals
      assert_equal ["10% off", "CAD 5.00 off"], totals.adjustments.map(&:label)
      assert_equal cad(8500), totals.total
    end

    def test_tax_on_discounted_total
      cart = Cart.new(currency: "CAD", tax_rate: 13)
      cart.add("tee", cad(10_000))
      cart.apply(FixedOff.new(amount: cad(2000)))
      totals = cart.totals
      assert_equal cad(1040), totals.tax
      assert_equal cad(9040), totals.total
      assert_equal cad(2000), totals.discount
    end

    def test_rounding_is_bankers
      assert_equal cad(2), cad(25).percent(10)
      assert_equal cad(4), cad(35).percent(10)
    end

    def test_currency_mismatch
      assert_raises(CurrencyMismatch) { cad(100) + Money.new(cents: 100, currency: "USD") }
      assert_raises(CurrencyMismatch) { @cart.add("tee", Money.new(cents: 100, currency: "USD")) }
    end

    def test_rejects_bad_input
      assert_raises(ArgumentError) { @cart.add("tee", cad(100), 0) }
      assert_raises(ArgumentError) { PercentOff.new(rate: 120) }
    end
  end
end
