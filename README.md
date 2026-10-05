# Order dependency

This program asks an OpenAI model multiple-choice questions from parquet files and records which letter it picks. With `RANDOMIZE_OPTIONS=true`, each question is asked four times, once with the correct choice in A, B, C, and D.

Results are written to a CSV named after the model and the option order, for example `gpt-4o-mini_fixed.csv` or `gpt-4o-mini_randomized.csv`.

## Install Ruby

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
| `OPENAI_MODEL` | no | `gpt-4o-mini` | Chat model that answers the questions. Also used in the CSV filename |
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
