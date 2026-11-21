require "yaml"
def deep_merge(a, b) = a.merge(b) { |_, x, y| x.is_a?(Hash) && y.is_a?(Hash) ? deep_merge(x, y) : y }
keys = {
  "en" => {
    "parties" => {"bella_daily_limit" => "You've reached today's limit of %{count} Bella plans. Try again tomorrow."},
    "dashboard" => {"parties" => {
      "prep_plan" => {"bella_status" => {
        "planning" => "Bella is planning",
        "planning_hint" => "This takes about a minute. Your plan stays as it is until then.",
        "failed" => "Bella couldn't finish this plan. Your plan hasn't changed."
      }},
      "bella_actions" => {"index" => {"in_progress" => "Bella is working on your plan."}}
    }}
  },
  "fr-CA" => {
    "parties" => {"bella_daily_limit" => "Vous avez atteint la limite de %{count} plans de Bella pour aujourd'hui. Réessayez demain."},
    "dashboard" => {"parties" => {
      "prep_plan" => {"bella_status" => {
        "planning" => "Bella prépare votre plan",
        "planning_hint" => "Ça prend environ une minute. Votre plan reste tel quel d'ici là.",
        "failed" => "Bella n'a pas pu terminer ce plan. Votre plan n'a pas changé."
      }},
      "bella_actions" => {"index" => {"in_progress" => "Bella travaille sur votre plan."}}
    }}
  }
}
{"en" => "config/locales/en.yml", "fr-CA" => "config/locales/fr-CA.yml"}.each do |locale, path|
  data = YAML.load_file(path)
  data[locale] = deep_merge(data[locale], keys[locale])
  File.write(path, data.to_yaml(line_width: -1))
end
