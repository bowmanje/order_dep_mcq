require "dotenv/load"
require "openai"
require_relative "lib/dataset"
require "csv"
# One ordering per letter. The correct option sits at that position and the
# other options keep their original relative order, so position is the thing
# that changes between calls.
def orders_by_answer_position(options, answer_text, randomize_options = false)
  correct, distractors = options.partition { |option| option == answer_text }
  raise "answer text is not one of the options: #{answer_text.inspect}" unless correct.size == 1

  return [options] unless randomize_options

  LABELS.each_index.map do |position|
    placed = distractors.dup
    placed.insert(position, correct.first)
    placed
  end
end

def prompt_for(statement, ordered_options)
  choices = LABELS.zip(ordered_options).map { |label, text| "#{label}. #{text}" }.join("\n")

  <<~PROMPT
    Answer the multiple choice question. Reply with only the letter of your choice (A, B, C, or D).

    #{statement}

    #{choices}
  PROMPT
end

def chosen_label(content)
  content.to_s.upcase[/\b([ABCD])\b/, 1]
end

def ask(client, statement, ordered_options)
  response = client.chat.completions.create(
    model: MODEL,
    temperature: 0,
    messages: [{ role: "user", content: prompt_for(statement, ordered_options) }]
  )

  chosen_label(response.choices.first.message.content)
end

LABELS = %w[A B C D].freeze
MODEL = ENV.fetch("OPENAI_MODEL", "gpt-4o-mini")
DATASET_PATH = ENV.fetch("DATASET_PATH")
LIMIT = Integer(ENV.fetch("QUESTION_LIMIT", 25))
RANDOMIZE_OPTIONS = ENV.fetch("RANDOMIZE_OPTIONS", "false").downcase == "true"

puts "DATASET_PATH=#{DATASET_PATH}"

# import the dataset if it doesn't exist
Dataset.import_dataset(DATASET_PATH) unless File.exist?("#{FileUtils.pwd}/datasets.db")

client = OpenAI::Client.new(api_key: ENV.fetch("OPENAI_API_KEY"))
trials = []
Dataset.fetch_questions_with_answers(LIMIT).each do |question|
  orders_by_answer_position(question[:options], question[:answer_text], RANDOMIZE_OPTIONS).each do |ordered|
    correct_index = ordered.index(question[:answer_text])
    label = ask(client, question[:statement], ordered)
    chosen_index = LABELS.index(label)
    correct = !chosen_index.nil? && ordered[chosen_index] == question[:answer_text]
    correct_position = LABELS[correct_index]

    trials << {
      statement: question[:statement],
      options: ordered,
      answer_text: question[:answer_text],
      correct_position: correct_position,
      chosen: label,
      correct: correct
    }

  end
end

CSV.open("#{MODEL}_#{RANDOMIZE_OPTIONS ? "randomized" : "fixed"}.csv", "w") do |csv|
  csv << ["statement", *LABELS, "correct_position", "chosen", "correct"]
  trials.each do |trial|
    csv << [trial[:statement], *trial[:options], trial[:correct_position], trial[:chosen], trial[:correct]]
  end
end