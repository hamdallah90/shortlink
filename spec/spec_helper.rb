# frozen_string_literal: true

require "fileutils"

ENV["RACK_ENV"] = "test"
ENV["DATA_PATH"] = File.expand_path("tmp/store.json", __dir__)

require_relative "../app"

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.before(:each) do
    FileUtils.rm_f(ENV["DATA_PATH"])
    ENV.delete("BASE_URL")
    Sinatra::Application.set :algurathem, "random"
    Sinatra::Application.set :shortlink_key, "shortlink-static-key"
    Sinatra::Application.set :recaptcha_site_key, nil
    Sinatra::Application.set :recaptcha_secret_key, nil
    Sinatra::Application.set :recaptcha_verifier, RecaptchaVerifier.new(nil)
    Sinatra::Application.set :codec, nil
    Sinatra::Application.set :generator, ShortCodeGenerator.new(
      algorithm: Sinatra::Application.settings.algurathem,
      length: Sinatra::Application.settings.token_length
    )
    Sinatra::Application.set :data_store, DataStore.new(
      ENV["DATA_PATH"],
      generator: Sinatra::Application.settings.generator
    )
  end
end

def app
  Sinatra::Application
end
