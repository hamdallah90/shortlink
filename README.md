# ShortLink

A minimal URL shortening service in Ruby with `/encode` and `/decode` endpoints.

## Web UI

Open `http://localhost:9292` for a simple UI to encode/decode URLs. Short links redirect directly to the original URL via `GET /:code`.

## API

### POST /encode
Request body:

```json
{ "url": "https://codesubmit.io/library/react" }
```

Response:

```json
{ "short_url": "http://your.domain/GeAi9K" }
```

### POST /decode
Request body:

```json
{ "short_url": "http://your.domain/GeAi9K" }
```

Response:

```json
{ "url": "https://codesubmit.io/library/react" }
```

## Persistence

Mappings are stored in a JSON file (`data/store.json` by default) so decoding works after a restart when `ALGURATHEM=random`. In `keyed_hash` mode, the token embeds the URL and `/decode` is stateless, so the JSON store is not used.

## Token generation

Short codes are exactly 10 characters and contain upper/lowercase letters and digits in `random` mode. You can switch algorithms:

- `random` (default): random 10-char token.
- `keyed_hash`: encrypts the URL using a static key and returns a longer, URL-safe token. This mode does not require a data store because `/decode` can decrypt the token.

Configure with:

- `ALGURATHEM` (or `ALGORITHM`) to select `random` or `keyed_hash`
- `SHORTLINK_KEY` for the keyed hash secret (ignored in `random` mode)
- `RECAPTCHA_SITE_KEY`, `RECAPTCHA_SECRET_KEY`, `RECAPTCHA_MIN_SCORE` to enable reCAPTCHA v3 on `/encode`

## Security considerations (attack vectors)

- Input abuse: Large payloads or deeply nested JSON can increase memory usage. In production, enforce body size limits at the web server or Rack middleware.
- URL validation: Invalid or non-http(s) URLs could be stored. The implementation only accepts http/https URLs with a host, but further normalization and allow-lists may be needed.
- Enumeration: Short codes can be guessed if enough are probed. Random tokens reduce predictability; add rate limiting and monitoring in production.
- Brute force: The `/decode` endpoint can be abused to probe for valid codes. Add throttling and monitoring in production.
- Data store tampering: The JSON file is plain text. In production, use a protected database with access controls and backups.
- Lack of authentication: Anyone can create links. Add authentication/authorization for private services.
- Secret management: The keyed hash mode relies on `SHORTLINK_KEY`. Store secrets securely and rotate if exposed.
- Key rotation: Changing `SHORTLINK_KEY` invalidates previously generated tokens.
- reCAPTCHA verification: If enabled, `/encode` will reject requests that fail verification. Ensure server-side verification uses the correct secret key.

## Scalability and collision handling

- Current approach generates a random alphanumeric token and checks for collisions before storing.
- For multiple processes or distributed systems, use a database with a unique index on the short code to guarantee uniqueness, or generate IDs via a centralized counter (e.g., Redis INCR) or distributed ID systems (e.g., Snowflake).
- Random tokens reduce predictability but must still check collisions on write; a database unique constraint makes collision handling safe.
- The `keyed_hash` mode is stateless and avoids collision checks, but token length grows with URL length.
- The JSON file is not safe for high concurrency or large data. A persistent database (PostgreSQL, Redis) is recommended for production scale.

## Running

See `RUNNING.md` for setup, running the server, and running tests.
