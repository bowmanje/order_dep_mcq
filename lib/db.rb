require "sqlite3"

class Db
  attr_reader :db

  def initialize
    return if @db
    @db = SQLite3::Database.new("#{FileUtils.pwd}/datasets.db")
  end
  
  def last_insert_row_id
    @db.last_insert_row_id
  end

  def close
    @db.close
  end

  def insert_question(statement, answer_text)
    @db.execute("INSERT INTO questions (statement, answer_text) VALUES (?, ?)", [statement, answer_text])
  end

  def insert_answer_options(question_id, *options)
    @db.execute("INSERT INTO answer_options (question_id, option_a, option_b, option_c, option_d) VALUES (?, ?, ?, ?, ?)", [question_id, *options])
  end

  def create_tables
    @db.execute("CREATE TABLE IF NOT EXISTS questions (id INTEGER PRIMARY KEY, statement TEXT, answer_text TEXT)")
    @db.execute("CREATE TABLE IF NOT EXISTS answer_options (id INTEGER PRIMARY KEY, question_id INTEGER, option_a TEXT, option_b TEXT, option_c TEXT, option_d TEXT)")
    @db.execute("CREATE TABLE IF NOT EXISTS trials (id INTEGER PRIMARY KEY, question_id INTEGER, option_a TEXT, option_b TEXT, option_c TEXT, option_d TEXT, correct_position TEXT, chosen TEXT)")
  end

  def self.insert_trial(question_id, option_a, option_b, option_c, option_d, correct_position, chosen)
    new.db.execute("INSERT INTO trials (question_id, option_a, option_b, option_c, option_d, correct_position, chosen) VALUES (?, ?, ?, ?, ?, ?, ?)", [question_id, option_a, option_b, option_c, option_d, correct_position, chosen])
  end

  def self.fetch_trials(limit)
    new.db.execute("SELECT correct_position, chosen FROM trials limit ?", [limit]).map do |row|
      {
        correct_position: row[0],
        chosen: row[1],
        correct: row[0] == row[1]
      }
    end
  end
end