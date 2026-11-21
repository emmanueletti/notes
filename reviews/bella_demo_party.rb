# bin/rails runner ~/notes/reviews/bella_demo_party.rb mackenzie@studio.com
# Creates a dinner party with real recipes and an empty plan, for trying Bella.
email = ARGV.first || "mackenzie@studio.com"
host = User.find_by!(email: email)
space = host.memberships.first.space
zone = Time.find_zone(host.timezone) || Time.zone

recipes = [
  {
    course: "appetizer", name: "Whipped Ricotta Crostini with Hot Honey", prep: 15, cook: 10, serves: 6,
    ingredients: ["1 baguette", "3 tbsp olive oil", "2 cups whole-milk ricotta", "1 lemon, zested", "1/2 tsp flaky salt",
      "1/4 cup honey", "1/2 tsp chili flakes", "Fresh thyme leaves"],
    steps: [
      "Heat the oven to 400F. Slice the baguette on an angle about 1/2 inch thick, brush with olive oil and toast on a sheet pan for 8 to 10 minutes until golden.",
      "Whip the ricotta with the lemon zest, a pinch of salt and a splash of olive oil in a food processor until very smooth, about 2 minutes.",
      "Warm the honey with the chili flakes in a small pan for a minute, then let it infuse off the heat.",
      "Spread the ricotta on the toasts, drizzle with the hot honey and scatter with thyme and flaky salt just before serving."
    ]
  },
  {
    course: "main", name: "Red Wine Braised Short Ribs", prep: 30, cook: 180, serves: 6,
    ingredients: ["4 lb bone-in beef short ribs", "2 tsp kosher salt", "1 tsp black pepper", "2 tbsp vegetable oil",
      "1 onion, diced", "2 carrots, diced", "2 celery stalks, diced", "4 garlic cloves, smashed", "2 tbsp tomato paste",
      "1 bottle dry red wine", "2 cups beef stock", "3 sprigs thyme", "2 bay leaves"],
    steps: [
      "Season the short ribs all over with salt and pepper, ideally an hour before cooking.",
      "Heat the oven to 325F. Brown the ribs well on all sides in the oil in a Dutch oven, in batches, then set aside.",
      "Pour off all but 2 tbsp of fat. Soften the onion, carrot and celery for 8 minutes, then add the garlic and tomato paste and cook 2 minutes more.",
      "Add the wine, scraping up the browned bits, and simmer until reduced by half, about 15 minutes.",
      "Return the ribs, add the stock, thyme and bay, cover and braise in the oven for 3 hours until the meat is falling off the bone.",
      "Lift out the ribs, skim the fat from the sauce and simmer it until glossy and reduced by a third. Serve the ribs with the sauce spooned over."
    ]
  },
  {
    course: "side", name: "Fresh Pappardelle with Brown Butter and Sage", prep: 45, cook: 5, serves: 6,
    ingredients: ["3 cups 00 flour", "4 large eggs", "1 tbsp olive oil", "6 tbsp unsalted butter", "16 sage leaves",
      "1/2 cup grated parmesan", "Salt for the pasta water"],
    steps: [
      "Mound the flour, make a well, add the eggs and olive oil and work into a dough. Knead for 8 to 10 minutes until smooth and elastic.",
      "Wrap the dough and rest it at room temperature for at least 30 minutes.",
      "Roll the dough thin with a pasta machine or rolling pin, dust with flour and cut into wide 1-inch ribbons. Toss with flour and keep on a tray.",
      "Bring a large pot of well-salted water to a boil.",
      "Brown the butter with the sage leaves in a wide pan until nutty and the sage is crisp.",
      "Boil the pappardelle for 2 to 3 minutes, toss in the brown butter with a splash of pasta water and the parmesan, and serve at once."
    ]
  },
  {
    course: "side", name: "Little Gem Salad with Lemon-Parmesan Dressing", prep: 15, cook: nil, serves: 6,
    ingredients: ["4 heads little gem lettuce", "1 lemon, juiced", "1 tsp Dijon mustard", "1 small garlic clove, grated",
      "1/3 cup olive oil", "1/2 cup finely grated parmesan", "1/4 cup toasted breadcrumbs", "Salt and pepper"],
    steps: [
      "Separate, wash and thoroughly dry the lettuce leaves, then chill them wrapped in a towel.",
      "Whisk the lemon juice, Dijon and garlic, then slowly whisk in the olive oil and half the parmesan. Season with salt and pepper.",
      "Just before serving, toss the leaves with the dressing and top with the rest of the parmesan and the breadcrumbs."
    ]
  },
  {
    course: "dessert", name: "Olive Oil Chocolate Mousse", prep: 25, cook: nil, serves: 6,
    ingredients: ["7 oz dark chocolate (70%), chopped", "1/3 cup good olive oil", "4 large eggs, separated", "1/4 cup sugar",
      "1/4 tsp flaky salt", "Whipped cream, to serve"],
    steps: [
      "Melt the chocolate gently over a pot of barely simmering water, then whisk in the olive oil until glossy.",
      "Whisk the egg yolks into the chocolate one at a time.",
      "Whip the egg whites to soft peaks, then add the sugar and whip to firm, glossy peaks.",
      "Fold the whites into the chocolate in three additions, keeping as much air as you can.",
      "Spoon into six glasses and chill for at least 4 hours, or overnight.",
      "Top with a little whipped cream and flaky salt right before serving."
    ]
  }
]

party = host.hosted_parties.create!(
  name: "Dinner for six",
  starts_at: zone.now.tomorrow.change(hour: 19, min: 0),
  meal_type: "dinner"
)

recipes.each do |attributes|
  recipe = space.recipes.build(
    name: attributes[:name],
    prep_time_minutes: attributes[:prep],
    cook_time_minutes: attributes[:cook],
    serves: attributes[:serves],
    created_by: host,
    user_created: true
  )
  attributes[:ingredients].each_with_index { |line, index| recipe.ingredients.build(original_text: line, position: index) }
  attributes[:steps].each_with_index { |step, index| recipe.steps.build(description: step, position: index) }
  recipe.save!
  party.dishes.create!(recipe: recipe, owner: host, course: attributes[:course])
end

puts "Party #{party.id}: #{party.name}, #{party.starts_at_in_host_zone.strftime("%A %-l:%M %p")}, #{party.dishes.count} dishes"
puts "/dashboard/parties/#{party.id}?tab=prep_plan"
