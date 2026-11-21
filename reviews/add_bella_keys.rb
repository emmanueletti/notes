require "yaml"
def deep_merge(a, b) = a.merge(b) { |_, x, y| x.is_a?(Hash) && y.is_a?(Hash) ? deep_merge(x, y) : y }

keys = {
  "en" => {
    "bella" => {
      "plan_actions" => {
        "build" => {"label" => "Build me a plan", "description" => "Turns your menu into a prep timeline."},
        "catch_up" => {"label" => "Catch me up", "description" => "Moves overdue tasks into the time you have left."},
        "rebuild" => {"label" => "Rebuild my plan", "description" => "Starts over from your menu. Done tasks stay done."}
      },
      "plan_presets" => {
        "day_of" => {"label" => "Only on the party day", "description" => "All the prep happens on the day itself."},
        "day_before" => {"label" => "Start the day before", "description" => "Prep anything that keeps a day ahead, so the event day is lighter."}
      }
    },
    "parties" => {
      "not_found" => "That party couldn't be found.",
      "task_not_found" => "That task is no longer on the plan.",
      "plan_version_not_found" => "That version is no longer in the history.",
      "bella_action_not_found" => "Pick something for Bella to do.",
      "plan_version_restored" => "Restored",
      "plan_version_sources" => {"host" => "You", "bella" => "Bella"}
    },
    "dashboard" => {"parties" => {
      "prep_plan" => {"plan_history" => "Plan history", "ask_bella" => "ask bella", "loading" => "One moment"},
      "plan_versions" => {"index" => {"title" => "Plan history", "current" => "Current", "restore" => "Restore", "restore_confirm" => "Restore this version?", "restore_confirm_description" => "Your current plan stays in the history."}},
      "bella_actions" => {"index" => {"needs_dishes" => "Add dishes to your menu first. Bella plans around them.", "go_to_menu" => "Go to the menu"}},
      "bella_plans" => {"new" => {"prep_timing" => "Prep timing"}}
    }}
  },
  "fr-CA" => {
    "bella" => {
      "plan_actions" => {
        "build" => {"label" => "Créer mon plan", "description" => "Transforme votre menu en échéancier de préparatifs."},
        "catch_up" => {"label" => "Rattraper mon retard", "description" => "Replace les tâches en retard dans le temps qu'il vous reste."},
        "rebuild" => {"label" => "Refaire mon plan", "description" => "Repart de votre menu. Les tâches terminées le restent."}
      },
      "plan_presets" => {
        "day_of" => {"label" => "Seulement le jour de la fête", "description" => "Tous les préparatifs se font le jour même."},
        "day_before" => {"label" => "Commencer la veille", "description" => "Préparez la veille tout ce qui se conserve, pour alléger le jour de la fête."}
      }
    },
    "parties" => {
      "not_found" => "Cette fête est introuvable.",
      "task_not_found" => "Cette tâche ne fait plus partie du plan.",
      "plan_version_not_found" => "Cette version ne fait plus partie de l'historique.",
      "bella_action_not_found" => "Choisissez une action pour Bella.",
      "plan_version_restored" => "Restaurée",
      "plan_version_sources" => {"host" => "Vous", "bella" => "Bella"}
    },
    "dashboard" => {"parties" => {
      "prep_plan" => {"plan_history" => "Historique du plan", "ask_bella" => "demandez à bella", "loading" => "Un instant"},
      "plan_versions" => {"index" => {"title" => "Historique du plan", "current" => "Actuelle", "restore" => "Restaurer", "restore_confirm" => "Restaurer cette version?", "restore_confirm_description" => "Votre plan actuel reste dans l'historique."}},
      "bella_actions" => {"index" => {"needs_dishes" => "Ajoutez d'abord des plats au menu. Bella prépare le plan à partir de ceux-ci.", "go_to_menu" => "Aller au menu"}},
      "bella_plans" => {"new" => {"prep_timing" => "Moment des préparatifs"}}
    }}
  }
}

{"en" => "config/locales/en.yml", "fr-CA" => "config/locales/fr-CA.yml"}.each do |locale, path|
  data = YAML.load_file(path)
  data[locale] = deep_merge(data[locale], keys[locale])
  File.write(path, data.to_yaml(line_width: -1))
end
