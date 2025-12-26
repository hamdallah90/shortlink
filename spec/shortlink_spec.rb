# frozen_string_literal: true

require "json"
require "rack/test"
require "rspec"

require_relative "spec_helper"

RSpec.describe "ShortLink API" do
  let(:headers) do
    {
      "CONTENT_TYPE" => "application/json",
      "HTTP_HOST" => "short.test"
    }
  end

  it "encodes and decodes a URL" do
    post "/encode", { url: "https://codesubmit.io/library/react" }.to_json, headers
    expect(last_response.status).to eq(200)

    short_url = JSON.parse(last_response.body)["short_url"]
    expect(short_url).to match(%r{\Ahttp://short\.test/})
    short_code = short_url.split("/").last
    expect(short_code).to match(/\A[0-9A-Za-z]{10}\z/)

    post "/decode", { short_url: short_url }.to_json, headers
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)["url"]).to eq("https://codesubmit.io/library/react")
  end

  it "reuses the same short code for the same URL" do
    post "/encode", { url: "https://example.com" }.to_json, headers
    short_url_1 = JSON.parse(last_response.body)["short_url"]

    post "/encode", { url: "https://example.com" }.to_json, headers
    short_url_2 = JSON.parse(last_response.body)["short_url"]

    expect(short_url_2).to eq(short_url_1)
  end

  it "redirects a short code to the original URL" do
    post "/encode", { url: "https://example.com/redirect" }.to_json, headers
    short_url = JSON.parse(last_response.body)["short_url"]
    short_code = short_url.split("/").last

    get "/#{short_code}", {}, headers
    expect(last_response.status).to eq(302)
    expect(last_response.headers["Location"]).to eq("https://example.com/redirect")
  end

  it "returns 400 for an invalid URL" do
    post "/encode", { url: "not-a-url" }.to_json, headers
    expect(last_response.status).to eq(400)
  end

  it "returns 404 for an unknown short code" do
    post "/decode", { short_url: "http://short.test/missing" }.to_json, headers
    expect(last_response.status).to eq(404)
  end

  it "persists mappings across restarts" do
    post "/encode", { url: "https://example.com/persist" }.to_json, headers
    short_url = JSON.parse(last_response.body)["short_url"]

    data_path = Sinatra::Application.settings.data_path
    Sinatra::Application.set :data_store, DataStore.new(
      data_path,
      generator: Sinatra::Application.settings.generator
    )

    post "/decode", { short_url: short_url }.to_json, headers
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)["url"]).to eq("https://example.com/persist")
  end

  it "returns 400 for invalid JSON" do
    post "/encode", "{", headers
    expect(last_response.status).to eq(400)
  end

  it "supports keyed_hash algorithm tokens" do
    Sinatra::Application.set :algurathem, "keyed_hash"
    Sinatra::Application.set :shortlink_key, "test-key"
    Sinatra::Application.set :codec, KeyedCipher.new(Sinatra::Application.settings.shortlink_key)
    Sinatra::Application.set :data_store, nil

    original_url = "https://example.com/keyed"
    post "/encode", { url: original_url }.to_json, headers
    short_url = JSON.parse(last_response.body)["short_url"]
    short_code = short_url.split("/").last

    expect(short_code.length).to be > 10

    post "/decode", { short_url: short_url }.to_json, headers
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)["url"]).to eq(original_url)
  end
end
