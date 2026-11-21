# bin/rails runner ~/notes/reviews/reset_bella_demo.rb [party_id]
# Empties a demo party's prep plan: one empty version, no history. Keeps Bella's
# past runs so the dev stub can replay them.
party = Party.find(ARGV.first || 95)
keep = party.plan_versions.create!(source: "host")
old = party.plan_versions.where.not(id: keep.id)
party.llm_generations.where(party_plan_version_id: old.select(:id)).update_all(party_plan_version_id: nil)
old.destroy_all
puts "Party #{party.id}: #{party.all_plan_tasks.count} tasks, #{party.plan_versions.count} version"
