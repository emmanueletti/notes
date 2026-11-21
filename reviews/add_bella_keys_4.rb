require "yaml"
def deep_merge(a, b) = a.merge(b) { |_, x, y| x.is_a?(Hash) && y.is_a?(Hash) ? deep_merge(x, y) : y }
keys = {
  "en" => {"bella" => {"plan_chores" => {"groceries" => "Groceries", "tidy_up" => "Tidy up", "bathroom" => "Clean the bathroom", "laundry" => "Laundry"}},
           "dashboard" => {"parties" => {"bella_plans" => {"new" => {"chores" => "Also fit in"}}}}},
  "fr-CA" => {"bella" => {"plan_chores" => {"groceries" => "Épicerie", "tidy_up" => "Ranger", "bathroom" => "Nettoyer la salle de bain", "laundry" => "Lessive"}},
              "dashboard" => {"parties" => {"bella_plans" => {"new" => {"chores" => "Prévoir aussi"}}}}}
}
{"en" => "config/locales/en.yml", "fr-CA" => "config/locales/fr-CA.yml"}.each do |locale, path|
  data = YAML.load_file(path)
  data[locale] = deep_merge(data[locale], keys[locale])
  File.write(path, data.to_yaml(line_width: -1))
end
