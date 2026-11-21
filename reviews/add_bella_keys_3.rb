require "yaml"
def deep_merge(a, b) = a.merge(b) { |_, x, y| x.is_a?(Hash) && y.is_a?(Hash) ? deep_merge(x, y) : y }
keys = {
  "en" => {"dashboard" => {"parties" => {"prep_plan" => {"bella_status" => {
    "rate_prompt" => "How's this plan?", "rate_up" => "Good plan", "rate_down" => "Not quite right",
    "rated" => "Thanks for the feedback.", "undo" => "Undo",
    "undo_confirm" => "Undo Bella's plan?", "undo_confirm_description" => "Your plan goes back to how it was. Bella's plan stays in the history."
  }}}}},
  "fr-CA" => {"dashboard" => {"parties" => {"prep_plan" => {"bella_status" => {
    "rate_prompt" => "Ce plan vous convient?", "rate_up" => "Bon plan", "rate_down" => "Pas tout à fait",
    "rated" => "Merci pour votre avis.", "undo" => "Annuler",
    "undo_confirm" => "Annuler le plan de Bella?", "undo_confirm_description" => "Votre plan redevient comme avant. Le plan de Bella reste dans l'historique."
  }}}}}
}
{"en" => "config/locales/en.yml", "fr-CA" => "config/locales/fr-CA.yml"}.each do |locale, path|
  data = YAML.load_file(path)
  data[locale] = deep_merge(data[locale], keys[locale])
  File.write(path, data.to_yaml(line_width: -1))
end
