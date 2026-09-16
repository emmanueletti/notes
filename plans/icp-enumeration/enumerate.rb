require "net/http"
require "json"
require "csv"
require "set"

API_KEY = ENV.fetch("GOOGLE_PLACES_API_KEY")
ENDPOINT = URI("https://places.googleapis.com/v1/places:searchText")
FIELDS = [
  "places.id",
  "places.displayName",
  "places.formattedAddress",
  "places.websiteUri",
  "places.nationalPhoneNumber",
  "places.rating",
  "places.userRatingCount",
  "places.primaryType",
  "places.businessStatus",
  "nextPageToken"
].join(",")

EN_QUERIES = [
  "custom jewellery",
  "goldsmith",
  "jewellery repair",
  "custom engagement rings",
  "jewellery studio"
]

FR_QUERIES = [
  "bijoux sur mesure",
  "joaillier",
  "reparation de bijoux",
  "bague de fiancailles sur mesure",
  "atelier de joaillerie"
]

CITIES = [
  ["Toronto, Ontario", :en],
  ["Mississauga, Ontario", :en],
  ["Brampton, Ontario", :en],
  ["Hamilton, Ontario", :en],
  ["Ottawa, Ontario", :both],
  ["London, Ontario", :en],
  ["Kitchener Waterloo, Ontario", :en],
  ["Windsor, Ontario", :en],
  ["Oshawa, Ontario", :en],
  ["Kingston, Ontario", :en],
  ["Barrie, Ontario", :en],
  ["Guelph, Ontario", :en],
  ["Niagara Falls, Ontario", :en],
  ["Montreal, Quebec", :both],
  ["Laval, Quebec", :fr],
  ["Quebec City, Quebec", :fr],
  ["Gatineau, Quebec", :fr],
  ["Sherbrooke, Quebec", :fr],
  ["Trois-Rivieres, Quebec", :fr],
  ["Saguenay, Quebec", :fr],
  ["Vancouver, British Columbia", :en],
  ["Surrey, British Columbia", :en],
  ["Burnaby, British Columbia", :en],
  ["Victoria, British Columbia", :en],
  ["Kelowna, British Columbia", :en],
  ["Nanaimo, British Columbia", :en],
  ["Calgary, Alberta", :en],
  ["Edmonton, Alberta", :en],
  ["Red Deer, Alberta", :en],
  ["Lethbridge, Alberta", :en],
  ["Winnipeg, Manitoba", :en],
  ["Saskatoon, Saskatchewan", :en],
  ["Regina, Saskatchewan", :en],
  ["Halifax, Nova Scotia", :en],
  ["Moncton, New Brunswick", :both],
  ["Fredericton, New Brunswick", :en],
  ["Saint John, New Brunswick", :en],
  ["St Johns, Newfoundland", :en],
  ["Charlottetown, Prince Edward Island", :en],
  ["Whitehorse, Yukon", :en]
]

def search(query, page_token = nil)
  body = { textQuery: query, languageCode: "en", maxResultCount: 20 }
  body[:pageToken] = page_token if page_token

  request = Net::HTTP::Post.new(ENDPOINT)
  request["Content-Type"] = "application/json"
  request["X-Goog-Api-Key"] = API_KEY
  request["X-Goog-FieldMask"] = FIELDS
  request.body = JSON.generate(body)

  response = Net::HTTP.start(ENDPOINT.hostname, ENDPOINT.port, use_ssl: true, read_timeout: 30) do |http|
    http.request(request)
  end

  if response.code != "200"
    warn "  ! #{response.code} for #{query}: #{response.body.to_s[0, 200]}"
    return nil
  end

  JSON.parse(response.body)
end

def queries_for(locale)
  case locale
  when :en then EN_QUERIES
  when :fr then FR_QUERIES
  else EN_QUERIES + FR_QUERIES
  end
end

seen = Set.new
rows = []
calls = 0

CITIES.each do |city, locale|
  queries_for(locale).each do |term|
    query = "#{term} in #{city}"
    page_token = nil
    pages = 0

    loop do
      result = search(query, page_token)
      calls += 1
      break if result.nil?

      Array(result["places"]).each do |place|
        id = place["id"]
        next if id.nil? || seen.include?(id)
        next if place["businessStatus"] == "CLOSED_PERMANENTLY"

        seen << id
        rows << {
          name: place.dig("displayName", "text"),
          address: place["formattedAddress"],
          website: place["websiteUri"],
          phone: place["nationalPhoneNumber"],
          rating: place["rating"],
          reviews: place["userRatingCount"],
          type: place["primaryType"],
          search_city: city,
          matched_query: term,
          place_id: id
        }
      end

      page_token = result["nextPageToken"]
      pages += 1
      break if page_token.nil? || pages >= 3

      sleep 2
    end

    puts "#{city} / #{term} -> #{rows.size} unique so far"
    sleep 1
  end
end

CSV.open("places_raw.csv", "w") do |csv|
  csv << ["name", "address", "website", "phone", "rating", "reviews", "type", "search_city", "matched_query", "place_id"]
  rows.each do |row|
    csv << [row[:name], row[:address], row[:website], row[:phone], row[:rating], row[:reviews], row[:type], row[:search_city], row[:matched_query], row[:place_id]]
  end
end

puts
puts "#{rows.size} unique places written to places_raw.csv"
puts "#{calls} API calls"
puts "#{rows.count { |r| r[:website].nil? }} have no website"
