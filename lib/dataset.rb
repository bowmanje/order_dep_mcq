require "parquet"
require "sqlite3"
require_relative "db"

class Question < Struct.new(:statement, :answer_text); end

class AnswerOption < Struct.new(:text); end

class Dataset
  def self.import_dataset(files)
    db = Db.new
    db.create_tables

    files = files.split(",") if files.is_a?(String)
    files.each do |file|

      puts "importing #{file}..."
      Parquet.each_row(file).to_a.shuffle.each do |row|
        question = Question.new(row["question"], row["choices"][row["answer"]])
        answer_options = row["choices"].map { |choice| AnswerOption.new(choice) }
        # only import questions with 4 answer options
        next if answer_options.size != 4

        db.insert_question(question.statement, question.answer_text)
        question_id = db.last_insert_row_id
        db.insert_answer_options(question_id, *answer_options.map(&:text))
      end
    end

    db.close
  end

  def self.fetch_questions_with_answers(limit)
    db = Db.new
    question_ids = db.db.execute("SELECT id FROM questions").map { |row| row[0] }
    results = []
    question_ids.sample(limit).each do |question_id|
      db.db.execute("SELECT q.statement, a.option_a, a.option_b, a.option_c, a.option_d, q.answer_text from questions q LEFT JOIN answer_options a on q.id = a.question_id where q.id = ?", [question_id]).each do |row|
        results << {
          statement: row[0],
          options: [row[1], row[2], row[3], row[4]],
          answer_text: row[5]
        }
      end
    end
    db.close
    results
  end
end