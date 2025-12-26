# Running ShortLink

## Prerequisites

- Ruby >= 3.2.2
- Bundler

## Install dependencies

```bash
bundle install
```

## Environment configuration

Create a `.env` file (see `.env.example`) to configure defaults:

```bash
cp .env.example .env
```

## Run the server

```bash
bundle exec rackup
```

By default the service listens on `http://localhost:9292`. Open the URL in a browser for the web UI.

Optional environment variables:

- `BASE_URL` to override the base URL returned from `/encode`
- `DATA_PATH` to override where mappings are stored (default: `data/store.json`, ignored in `keyed_hash`)
- `ALGURATHEM` (or `ALGORITHM`) to choose `random` or `keyed_hash`
- `SHORTLINK_KEY` to provide the static key for `keyed_hash`
- `RECAPTCHA_SITE_KEY`, `RECAPTCHA_SECRET_KEY`, `RECAPTCHA_MIN_SCORE` to enable reCAPTCHA v3 on `/encode`

Example:

```bash
BASE_URL="http://localhost:9292" DATA_PATH="data/store.json" ALGURATHEM="random" bundle exec rackup
```

Keyed hash mode (stateless, no JSON store needed):

```bash
ALGURATHEM="keyed_hash" SHORTLINK_KEY="your-static-key" bundle exec rackup
```

## Run tests

```bash
bundle exec rspec
```

## Example requests

```bash
curl -X POST http://localhost:9292/encode \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://codesubmit.io/library/react"}'

curl -X POST http://localhost:9292/decode \
  -H 'Content-Type: application/json' \
  -d '{"short_url":"http://localhost:9292/GeAi9K"}'
```
