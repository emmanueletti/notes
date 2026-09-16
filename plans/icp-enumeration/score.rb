require "net/http"
require "csv"
require "uri"

CHAINS = [
  "peoples jeweller", "michael hill", "charm diamond", "ben moss", "mappins",
  "swarovski", "pandora", "tiffany", "birks", "cartier", "rolex", "kay jewelers",
  "zales", "jared", "claire's", "ardene", "walmart", "costco", "hudson's bay",
  "spence diamonds", "brilliant earth", "blue nile"
]

SHOPIFY = [/cdn\.shopify\.com/i, %r{/cdn/shop/}i, /Shopify\.theme/i, /shopify-section/i]
INSTAGRAM = [%r{instagram\.com/}i]
CUSTOM = [/\bcustom\b/i, /bespoke/i, /sur[- ]mesure/i, /one[- ]of[- ]a[- ]kind/i, /commission/i]
REPAIR = [/\brepair/i, /r[ée]paration/i, /resiz/i, /restoration/i, /remodel/i]
FRENCH = [/joaill/i, /bijou/i, /\bor\b.{0,20}\b18k\b/i, /lang=["']fr/i, /hreflang=["']fr/i]
BOOKING = [/book (a|an) (appointment|consultation)/i, /prendre rendez-vous/i, /calendly/i, /acuityscheduling/i, /appointment only/i]
DIY_PLATFORM = [/wix\.com/i, /squarespace/i, /wp-content/i, /webflow/i]

def fetch(url, redirects = 3)
  return nil if redirects.zero?

  uri = URI.parse(url)
  return nil unless uri.is_a?(URI::HTTP)

  request = Net::HTTP::Get.new(uri)
  request["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"
  request["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
  request["Accept-Language"] = "en-CA,en;q=0.9"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 15) do |http|
    http.request(request)
  end

  case response
  when Net::HTTPRedirection
    location = response["location"]
    return nil if location.nil?
    location = URI.join(url, location).to_s
    fetch(location, redirects - 1)
  when Net::HTTPSuccess
    response.body.to_s[0, 1_500_000].dup.force_encoding("UTF-8").scrub("")
  end
rescue StandardError => e
  warn "  ! #{url}: #{e.class}"
  nil
end

def hits?(body, patterns)
  patterns.any? { |pattern| body.match?(pattern) }
end

rows = CSV.read("places_raw.csv", headers: true)
puts "scoring #{rows.size} places"

results = []

rows.each_with_index do |row, index|
  name = row["name"].to_s
  website = row["website"].to_s.strip

  if CHAINS.any? { |chain| name.downcase.include?(chain) }
    results << [name, row["address"], website, row["phone"], -10, "C", "chain"]
    next
  end

  if website.empty?
    results << [name, row["address"], "", row["phone"], -3, "C", "no website"]
    next
  end

  body = fetch(website)
  sleep 1

  if body.nil?
    results << [name, row["address"], website, row["phone"], 0, "C", "unreachable"]
    next
  end

  score = 0
  signals = []

  if hits?(body, SHOPIFY) then score += 3; signals << "shopify" end
  if hits?(body, INSTAGRAM) then score += 2; signals << "instagram" end
  if hits?(body, CUSTOM) then score += 2; signals << "custom" end
  if hits?(body, REPAIR) then score += 2; signals << "repair" end
  if hits?(body, FRENCH) then score += 1; signals << "french" end
  if hits?(body, BOOKING) then score += 1; signals << "booking" end
  if !hits?(body, SHOPIFY) && hits?(body, DIY_PLATFORM) then score += 1; signals << "diy-platform" end

  tier = if score >= 8 then "A"
         elsif score >= 5 then "B"
         else "C"
         end

  results << [name, row["address"], website, row["phone"], score, tier, signals.join(" ")]
  puts "#{index + 1}/#{rows.size} #{tier} #{score} #{name}"
end

results.sort_by! { |r| -r[4] }

CSV.open("icp_scored.csv", "w") do |csv|
  csv << ["name", "address", "website", "phone", "score", "tier", "signals"]
  results.each { |r| csv << r }
end

puts
puts "written to icp_scored.csv"
["A", "B", "C"].each do |tier|
  puts "tier #{tier}: #{results.count { |r| r[5] == tier }}"
end
