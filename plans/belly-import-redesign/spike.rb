RUNS = Integer(ENV.fetch("RUNS", "5"))
RE = RecipeIngest::RecipeExtraction

OLD_FIRST_PARAGRAPH = RE::EXTRACTION_RULES.split("\n\n").first + "\n\n"
raise "rules changed shape" if !OLD_FIRST_PARAGRAPH.start_with?("Always call save_recipe. Set is_recipe")

NEW_FIRST_PARAGRAPH = <<~TEXT
  Always call save_recipe. Copy whatever recipe the source holds: every ingredient
  line it lists for one dish, and every method step it writes. When the source lists
  no ingredients, send no ingredients; when it writes no method, send no steps: a
  social caption often lists the ingredients and leaves the method to the video. A
  dish name, a description of a dish, or a promise of a recipe is neither an
  ingredient list nor a method, and neither is a note on storing, freezing, or
  serving the dish.

TEXT

NEW_RULES = RE::EXTRACTION_RULES.sub(OLD_FIRST_PARAGRAPH, NEW_FIRST_PARAGRAPH)

POINTS_ELSEWHERE_QUESTION = <<~TEXT
  Always answer points_elsewhere: do the caption's own words tell the reader where to
  go to get the recipe, such as a comment keyword, a DM, a link, the bio, an app, a
  newsletter, a subscription, a cookbook, a website, or another post? Answer false
  when no words say so. The post's own video or photos are not somewhere else, and
  hashtags never count, even one naming a platform such as #youtubeshorts. Belly,
  the app reading this caption, is not somewhere else either: a caption telling the
  reader to save the recipe to Belly or usebelly.app does not point elsewhere.
TEXT

CAPTION_PROMPT = <<~PROMPT
  You extract recipes from the caption of a social post.

  #{NEW_RULES}
  A caption is padded with hashtags, emoji, credits, and calls to follow or
  to comment for the recipe: ignore all of it.

  #{POINTS_ELSEWHERE_QUESTION}
PROMPT

PROMPTS = {
  caption: CAPTION_PROMPT,
  video_caption: CAPTION_PROMPT,
  text: "You extract recipes from text a cook has pasted in.\n\n#{NEW_RULES}",
  pin_blurb: "You extract recipes from the title and description of a Pinterest pin.\n\n#{NEW_RULES}\nA pin's title and description are padded with search keywords: ignore them.",
  url: "You extract recipes from webpage text.\n\n#{NEW_RULES}\nAn article, a shop page, or a listing of many recipes holds no single recipe: send no ingredients and no steps."
}

def tool_for(kind)
  tool = RE::SAVE_RECIPE_TOOL.deep_dup
  props = tool[:input_schema][:properties]
  props.delete(:is_recipe)
  props[:ingredients].delete(:minItems)
  props[:steps].delete(:minItems)
  tool[:input_schema][:required] = []
  if [:caption, :video_caption].include?(kind)
    props[:points_elsewhere] = {
      type: "boolean",
      description: "Whether the caption's own words send the reader somewhere else to get the recipe."
    }
  end
  tool
end

ExperimentalRequest = Struct.new(:kind, :text) do
  def model = RE::MODEL
  def max_tokens = RE::MAX_TOKENS
  def event_name = "llm.recipe_ingest_spike"
  def system_prompt = PROMPTS.fetch(kind)
  def tool = tool_for(kind)
  def content = "Extract the recipe from this #{{text: "text", url: "webpage", pin_blurb: "pin"}.fetch(kind, "caption")}:\n\n#{text}"
end

def rows(answers, key, field)
  Array(answers[key]).select { |row| row.respond_to?(:[]) && row[field].to_s.strip.present? }
end

WRITTEN_OUT_LINK = %r{https?://\S+}

def new_outcome(kind, text, ingredients, steps, points_elsewhere)
  return "success" if ingredients && steps
  return "INGREDIENTS_WITHOUT_METHOD" if ingredients
  return "STEPS_WITHOUT_INGREDIENTS" if steps
  return "NOT_A_RECIPE" if [:text, :url].include?(kind)
  return "RECIPE_IN_MEDIA" if kind == :pin_blurb
  return "FOLLOW_LINK" if text.match?(WRITTEN_OUT_LINK)
  return "RECIPE_GATED" if points_elsewhere

  "RECIPE_IN_MEDIA"
end

cases = Dir.glob(File.join(ENV.fetch("FIXTURES"), "*.json")).sort.map do |path|
  fixture = JSON.parse(File.read(path))
  {name: File.basename(path, ".json"), kind: fixture["kind"].to_sym, text: fixture["text"],
   new_expect: fixture["expect"], old_expect: fixture["current_expect"]}
end

def run_new(c)
  result = LlmGate.fetch(ExperimentalRequest.new(c[:kind], c[:text]))
  return {error: result.errors.first} if result.error?

  answers = result.data
  ingredients = rows(answers, "ingredients", "original_text").any?
  steps = rows(answers, "steps", "text").any?
  points_elsewhere = answers["points_elsewhere"] == true
  {ingredients: ingredients, steps: steps, points_elsewhere: points_elsewhere,
   ingredient_count: rows(answers, "ingredients", "original_text").size,
   outcome: new_outcome(c[:kind], c[:text], ingredients, steps, points_elsewhere)}
end

def run_old(c)
  result = RE.call((c[:kind] == :pin_blurb) ? :caption : c[:kind], text: c[:text])
  result.error? ? result.errors.first : "success"
end

jobs = cases.flat_map { |c| RUNS.times.map { |i| [c, i] } }
queue = Queue.new
jobs.each { |job| queue << job }
results = Hash.new { |h, k| h[k] = {new: [], old: []} }
lock = Mutex.new
threads = 4.times.map do
  Thread.new do
    while (job = (queue.pop(true) rescue nil))
      c, _i = job
      new_run = run_new(c)
      old_run = c[:old_expect] ? run_old(c) : nil
      lock.synchronize do
        results[c[:name]][:new] << new_run
        results[c[:name]][:old] << old_run if old_run
      end
    end
  end
end
threads.each(&:join)

File.write(ENV.fetch("OUT"), JSON.pretty_generate(cases.map { |c| c.merge(results: results[c[:name]]) }))
puts "done: #{cases.size} cases x #{RUNS} runs"
