# frozen_string_literal: true

require "dotenv/load"
require "sinatra"
require "json"
require "uri"

require_relative "lib/data_store"
require_relative "lib/keyed_cipher"
require_relative "lib/recaptcha_verifier"
require_relative "lib/short_code_generator"

configure do
  set :data_path, ENV.fetch("DATA_PATH", File.expand_path("data/store.json", __dir__))
  set :algurathem, ENV.fetch("ALGURATHEM", ENV.fetch("ALGORITHM", "random"))
  set :shortlink_key, ENV.fetch("SHORTLINK_KEY", "shortlink-static-key")
  set :token_length, 10
  set :recaptcha_site_key, ENV["RECAPTCHA_SITE_KEY"]
  set :recaptcha_secret_key, ENV["RECAPTCHA_SECRET_KEY"]
  set :recaptcha_min_score, ENV.fetch("RECAPTCHA_MIN_SCORE", "0.5").to_f
  set :recaptcha_verifier, RecaptchaVerifier.new(
    settings.recaptcha_secret_key,
    min_score: settings.recaptcha_min_score,
    action: "encode"
  )

  if settings.algurathem == "keyed_hash"
    set :codec, KeyedCipher.new(settings.shortlink_key)
    set :data_store, nil
  else
    set :generator, ShortCodeGenerator.new(
      algorithm: settings.algurathem,
      length: settings.token_length
    )
    set :data_store, DataStore.new(settings.data_path, generator: settings.generator)
  end
end

helpers do
  def parse_json_body
    request.body.rewind
    raw = request.body.read
    return {} if raw.nil? || raw.strip.empty?

    JSON.parse(raw)
  rescue JSON::ParserError
    halt 400, { error: "Invalid JSON" }.to_json
  end

  def normalize_url(input)
    return nil if input.nil? || input.strip.empty?

    uri = URI.parse(input)
    return nil unless uri.scheme && uri.host
    return nil unless %w[http https].include?(uri.scheme)

    uri.to_s
  rescue URI::InvalidURIError
    nil
  end

  def extract_short_code(input)
    return nil if input.nil? || input.strip.empty?

    uri = URI.parse(input)
    if uri.scheme && uri.host
      code = uri.path.sub(%r{^/}, "")
      return nil if code.empty?
      return code
    end

    input.strip
  rescue URI::InvalidURIError
    input.strip
  end

  def verify_recaptcha!(token)
    verifier = settings.recaptcha_verifier
    return unless verifier&.enabled?

    # TODO: add logging
    logger.info(settings.recaptcha_min_score)
    logger.info("Recaptcha verification: #{token} from #{request.ip}")
    valid = verifier.verify(token, remote_ip: request.ip)
    logger.info("Recaptcha verification result: #{valid}")
    halt 403, { error: "Recaptcha verification failed" }.to_json unless valid
  end
end

get "/" do
  content_type :html
  erb :index, locals: {
    recaptcha_site_key: settings.recaptcha_site_key,
    algurathem: settings.algurathem
  }
end

post "/encode" do
  content_type :json
  body = parse_json_body
  url = normalize_url(body["url"])
  halt 400, { error: "Invalid URL" }.to_json unless url

  verify_recaptcha!(body["recaptcha_token"])

  short_code = if settings.algurathem == "keyed_hash"
                 settings.codec.encode(url)
               else
                 settings.data_store.fetch_or_create(url)
               end
  base_url = ENV["BASE_URL"] || request.base_url

  { short_url: "#{base_url}/#{short_code}" }.to_json
end

post "/decode" do
  content_type :json
  body = parse_json_body
  short_code = extract_short_code(body["short_url"])
  halt 400, { error: "Invalid short URL" }.to_json unless short_code

  url = if settings.algurathem == "keyed_hash"
          settings.codec.decode(short_code)
        else
          settings.data_store.find(short_code)
        end
  halt 404, { error: "Short URL not found" }.to_json unless url

  { url: url }.to_json
end

get "/:code" do
  pass if %w[encode decode].include?(params[:code])

  short_code = params[:code]
  url = if settings.algurathem == "keyed_hash"
          settings.codec.decode(short_code)
        else
          settings.data_store.find(short_code)
        end

  unless url
    status 404
    content_type :html
    return erb :not_found
  end

  redirect url, 302
end
