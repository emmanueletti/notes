# TenantSequenced — Phase 2 & 3 (held, apply after Phase 1 deploys)

Phase 1 (dual-write + backfill) ships first. After it is deployed AND
`script/backfill_tenant_sequence.rb` has run clean (no duplicate report), apply
Phase 2. Phase 3 follows ~1 week after Phase 2.

## Pre-Phase-2 gate (duplicate check)
The Phase-1 backfill is a plain copy (`tenant_sequence = public_number`), so it is
safe even if duplicates exist. The unique index, added in Phase 2, is not. Before
running the Phase-2 index migration, confirm there are no duplicate
`(scope, public_number)` rows (old TenantCountable races could have left some):

```ruby
{Customer => :repair_shop_id, JobTicket => :repair_shop_id, JobItem => :job_ticket_id}.each do |model, scope|
  dupes = model.where.not(public_number: nil).group(scope, :public_number).having("COUNT(*) > 1").count
  puts dupes.any? ? "#{model.table_name}: #{dupes.inspect}" : "#{model.table_name}: clean"
end
```

If any table is not clean, renumber the newer duplicate row(s) before building the index.

## Phase 2 — switch + index + ignore

### Migrations (generate with `bin/rails g migration`, explicit up/down, `disable_statement_timeout!`)

`add_tenant_sequence_unique_indexes` (`disable_ddl_transaction!`, `algorithm: :concurrently`):
- customers / job_tickets: `[:repair_shop_id, :tenant_sequence] unique where "tenant_sequence IS NOT NULL"` named `index_<table>_on_tenant_sequence`
- job_items: `[:job_ticket_id, :tenant_sequence] unique where "tenant_sequence IS NOT NULL"` named `index_job_items_on_tenant_sequence`
- down: `remove_index ... algorithm: :concurrently`

`allow_null_public_number_on_counted_tables`:
- up: `change_column_null :customers/:job_tickets/:job_items, :public_number, true`
- down: `change_column_null ..., false`

### Concern — `app/models/concerns/tenant_sequenced.rb` (new)
```ruby
# frozen_string_literal: true

module TenantSequenced
  extend ActiveSupport::Concern

  included do
    before_create :assign_tenant_sequence, unless: -> { tenant_sequence.present? }
  end

  class_methods do
    def sequence_scope(column)
      @sequence_scope_column = column
    end

    def sequence_scope_column
      @sequence_scope_column || :repair_shop_id
    end
  end

  def public_number
    tenant_sequence
  end

  private

  def assign_tenant_sequence
    scope_column = self.class.sequence_scope_column
    scope_value = public_send(scope_column)

    acquire_sequence_lock(scope_column, scope_value)
    self.tenant_sequence = (self.class.unscoped.where(scope_column => scope_value).maximum(:tenant_sequence) || 0) + 1
  end

  def acquire_sequence_lock(scope_column, scope_value)
    key = "tenant_sequence:#{self.class.table_name}:#{scope_column}:#{scope_value}"
    quoted_key = self.class.connection.quote(key)
    self.class.connection.execute("SELECT pg_advisory_xact_lock(hashtextextended(#{quoted_key}, 0))")
  end
end
```

### Model edits
- Delete `app/models/concerns/tenant_countable.rb` (and the Phase-1 dual-write mirror it carries).
- `customer.rb`: `include TenantSequenced` (was TenantCountable); `self.ignored_columns += [:category, :public_number]`; drop the unique-constraint TODO.
- `job_ticket.rb`: `include TenantSequenced`; `self.ignored_columns += [:public_number]`; drop TODO; in `exact_id_match_items`, `find_by/where(public_number:)` -> `tenant_sequence:`.
- `job_item.rb`: `include TenantSequenced`; `self.ignored_columns += [:public_number]`; `sequence_scope :job_ticket_id` (was `countable_scope`).

### Query/write sites: `public_number:` -> `tenant_sequence:`
- `app/queries/customers_search.rb` (1), `app/queries/job_items_search.rb` (3)
- `app/services/template_renderer_service.rb` (3 preview builds: `JobTicket.new(tenant_sequence: 1234)`, items `tenant_sequence: 1/2`)
- `lib/tasks/customers.rake` (counter seeds from `maximum(:tenant_sequence)`, key `tenant_sequence:`)
- `lib/tasks/job_tickets.rake` (same; plus job_items insert `tenant_sequence: 1`)
- Leave the Shopify API response hash key `public_number:` (contract; value is the `.public_number` method).

### Tests
- New `test/models/concerns/tenant_sequenced_test.rb` (full version is below).
- `test/models/job_item_test.rb`: drop `public_number: 1` from the three `JobItem.new(...)` cases; the explicit-value test uses `tenant_sequence: 99`.
- `test/test_helper.rb`: remove the `TenantCountable` line from the concern-coverage TODO.
- Remove the Phase-1 dual-write mirror test.

### Phase-2 PR caveat to state
During the Phase-2 rolling deploy, a Phase-1 instance can read a Phase-2-created
row whose `public_number` is now NULL -> momentary blank number. Numbers are
continuous, so nothing changes value. Deploy in a quiet window if even that is unwanted.

## Phase 3 — drop column (much later, no fixed date)
The backfill script was already deleted in Phase 2. Phase 3 is just the column drop.
Grep `TODO: drop the public_number column` to find the two code edits.
- Migration `drop_public_number_from_counted_tables`:
  - up: `remove_column :customers/:job_tickets/:job_items, :public_number`
  - down: `add_column :customers, :public_number, :bigint`; `:job_tickets, :bigint`; `:job_items, :integer` (original types, nullable)
- Remove the `ignored_columns += [:public_number]` entries (leave `:category` on Customer).

## Full concern test (`test/models/concerns/tenant_sequenced_test.rb`)
```ruby
# frozen_string_literal: true

require "test_helper"

class TenantSequencedTest < ActiveSupport::TestCase
  def setup
    @repair_shop = create(:repair_shop)
    @customer = create(:customer, repair_shop: @repair_shop)
  end

  test "tenant_sequence is assigned on create" do
    ticket = create(:job_ticket, repair_shop: @repair_shop, customer: @customer)
    assert_not_nil ticket.tenant_sequence
  end

  test "#public_number returns tenant_sequence" do
    ticket = create(:job_ticket, repair_shop: @repair_shop, customer: @customer)
    assert_equal ticket.tenant_sequence, ticket.public_number
  end

  test "#public_number is nil on an unsaved record" do
    ticket = build(:job_ticket, repair_shop: @repair_shop, customer: @customer)
    assert_nil ticket.public_number
  end

  test "the first record in a scope is numbered 1" do
    ticket = create(:job_ticket, repair_shop: @repair_shop, customer: @customer)
    assert_equal 1, ticket.public_number
  end

  test "numbers increment in creation order within a scope" do
    tickets = create_list(:job_ticket, 3, repair_shop: @repair_shop, customer: @customer)
    assert_equal [1, 2, 3], tickets.map(&:public_number)
  end

  test "the sequence is scoped per repair_shop" do
    other_shop = create(:repair_shop)
    other_customer = create(:customer, repair_shop: other_shop)
    create(:job_ticket, repair_shop: other_shop, customer: other_customer)
    ticket = create(:job_ticket, repair_shop: @repair_shop, customer: @customer)
    assert_equal 1, ticket.public_number
  end

  test "an explicitly set tenant_sequence is preserved and not reassigned" do
    ticket = create(:job_ticket, repair_shop: @repair_shop, customer: @customer, tenant_sequence: 99)
    assert_equal 99, ticket.public_number
  end

  test "the partial unique index rejects a duplicate number in the same scope" do
    create(:job_ticket, repair_shop: @repair_shop, customer: @customer, tenant_sequence: 5)
    assert_raises(ActiveRecord::RecordNotUnique) do
      create(:job_ticket, repair_shop: @repair_shop, customer: @customer, tenant_sequence: 5)
    end
  end

  test "the same number can coexist in different scopes" do
    other_shop = create(:repair_shop)
    other_customer = create(:customer, repair_shop: other_shop)
    create(:job_ticket, repair_shop: @repair_shop, customer: @customer, tenant_sequence: 5)
    assert_nothing_raised do
      create(:job_ticket, repair_shop: other_shop, customer: other_customer, tenant_sequence: 5)
    end
  end

  test "assignment acquires a per-scope advisory lock" do
    locked = false
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      locked = true if payload[:sql]&.include?("pg_advisory_xact_lock")
    end
    create(:job_ticket, repair_shop: @repair_shop, customer: @customer)
    assert locked, "expected pg_advisory_xact_lock to be issued during assignment"
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  test "reading #public_number does not issue a write" do
    ticket = create(:job_ticket, repair_shop: @repair_shop, customer: @customer)
    ticket.reload
    writes = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      writes += 1 if payload[:sql]&.match?(/\A\s*update/i)
    end
    ticket.public_number
    ticket.public_number
    assert_equal 0, writes
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  test "a hard-deleted highest row frees its number" do
    ticket = create(:job_ticket, repair_shop: @repair_shop, customer: @customer)
    second_item = create(:job_item, job_ticket: ticket)
    assert_equal 2, second_item.public_number
    second_item.destroy!
    third_item = create(:job_item, job_ticket: ticket)
    assert_equal 2, third_item.public_number
  end

  test ".sequence_scope_column defaults to :repair_shop_id" do
    assert_equal :repair_shop_id, JobTicket.sequence_scope_column
    assert_equal :repair_shop_id, Customer.sequence_scope_column
  end

  test ".sequence_scope overrides the scope column" do
    assert_equal :job_ticket_id, JobItem.sequence_scope_column
  end

  test "job item numbers are scoped to their job_ticket" do
    ticket = create(:job_ticket, repair_shop: @repair_shop, customer: @customer)
    second_item = create(:job_item, job_ticket: ticket)
    assert_equal 2, second_item.public_number
  end

  test "job item sequences are independent per ticket" do
    ticket_a = create(:job_ticket, repair_shop: @repair_shop, customer: @customer)
    ticket_b = create(:job_ticket, repair_shop: @repair_shop, customer: @customer)
    assert_equal 2, create(:job_item, job_ticket: ticket_a).public_number
    assert_equal 2, create(:job_item, job_ticket: ticket_b).public_number
  end

  test "the migrated models include TenantSequenced" do
    assert_includes Customer.ancestors, TenantSequenced
    assert_includes JobTicket.ancestors, TenantSequenced
    assert_includes JobItem.ancestors, TenantSequenced
  end
end
```
