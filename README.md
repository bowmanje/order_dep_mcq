# Order dependency

This program asks an OpenAI model multiple-choice questions from parquet files and records which letter it picks. With `RANDOMIZE_OPTIONS=true`, each question is asked four times, once with the correct choice in A, B, C, and D.

## Install Ruby, Minimum Required Version (3.3.0)

On Ubuntu or Debian, including WSL:

```bash
sudo apt update
sudo apt install ruby-full build-essential
gem install bundler
```

Check that Ruby is available:

```bash
ruby -v
```

## Setup

From the project directory, install the gems:

```bash
bundle install
```

Copy the example environment file and add your OpenAI API key:

```bash
cp .env.example .env
```

The program loads `.env` automatically. Values you set on the command line override the file.

The first run imports `DATASET_PATH` into `datasets.db`. Later runs reuse that database. Delete `datasets.db` if you want to import a different set of files.

## Environment variables

| Variable | Required | Default | Used for |
| --- | --- | --- | --- |
| `OPENAI_API_KEY` | yes | | API key sent to OpenAI |
| `DATASET_PATH` | yes | | Comma-separated parquet files to import when `datasets.db` does not exist |
| `OPENAI_MODEL` | no | `gpt-4o-mini` | Chat model that answers the questions. Also used in the result filenames |
| `QUESTION_LIMIT` | no | `25` | How many questions to sample from the database |
| `RANDOMIZE_OPTIONS` | no | `false` | `true` moves the correct choice through A, B, C, and D. `false` keeps the original order and asks each question once |

`RANDOMIZE_OPTIONS` accepts `true` or `false`, compared case-insensitively.

## Run

Using the values in `.env`:

```bash
bundle exec ruby main.rb
```

Five questions, original option order:

```bash
QUESTION_LIMIT=5 RANDOMIZE_OPTIONS=false bundle exec ruby main.rb
```

Ten questions, correct answer placed in each letter position:

```bash
QUESTION_LIMIT=10 RANDOMIZE_OPTIONS=true bundle exec ruby main.rb
```

A different model, one parquet file, and three questions:

```bash
OPENAI_MODEL=gpt-4o DATASET_PATH=sample_data/anatomy.parquet QUESTION_LIMIT=3 bundle exec ruby main.rb
```

`DATASET_PATH` in that last example is only used when `datasets.db` is missing. Delete `datasets.db` first if you want that file imported.

## Output files

A run writes three files in the project directory. Result files are named from `OPENAI_MODEL` and `RANDOMIZE_OPTIONS`. A later run with the same model and the same option setting overwrites those two files.

| File | When it is written |
| --- | --- |
| `datasets.db` | First run, if the file is not already there. SQLite database of imported questions. Later runs read it and do not import again. |
| `<model>_fixed.csv` or `<model>_randomized.csv` | Every run. One row per question asked. `randomized` means the correct choice was moved through A, B, C, and D, so each question has four rows. |
| `<model>_fixed.json` or `<model>_randomized.json` | Every run. Counts summarized from that run. |

Examples: `gpt-4o-mini_fixed.csv`, `gpt-4o-mini_randomized.json`, `gpt-5.6_randomized.csv`.

### CSV columns

| Column | Meaning |
| --- | --- |
| `statement` | Question text |
| `A`, `B`, `C`, `D` | Option text in the order sent to the model |
| `correct_position` | Letter where the correct option was placed |
| `chosen` | Letter the model returned. Empty if the reply was not A, B, C, or D |
| `correct` | `true` when `chosen` matches `correct_position` |

### JSON fields

Both values are strings of `hits/total`.

`accuracy_by_position` is how often the model was right when the correct option sat in that letter. A lower number for one letter means the model missed more often when the answer was placed there.

`letter_selection_counts` is how often the model picked that letter, out of every trial. A higher number means the model favored that position.

```json
{
  "accuracy_by_position": { "A": "74/100", "B": "72/100", "C": "71/100", "D": "63/100" },
  "letter_selection_counts": { "A": "110/400", "B": "108/400", "C": "101/400", "D": "81/400" }
}
```
