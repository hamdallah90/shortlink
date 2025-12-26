# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

class RecaptchaVerifier
  VERIFY_URL = URI("https://www.google.com/recaptcha/api/siteverify")

  def initialize(secret_key, min_score: 0.5, action: "encode")
    @secret_key = secret_key.to_s
    @min_score = min_score.to_f
    @action = action
  end

  def enabled?
    !@secret_key.empty?
  end

  def verify(token, remote_ip: nil)
    return true unless enabled?
    return false if token.nil? || token.strip.empty?

    payload = { "secret" => @secret_key, "response" => token }
    payload["remoteip"] = remote_ip if remote_ip

    response = Net::HTTP.post_form(VERIFY_URL, payload)
    body = JSON.parse(response.body)

    return false unless body["success"]
    return false if @action && body["action"] && body["action"] != @action

    score = body["score"]
    return false if score && score.to_f < @min_score

    true
  rescue JSON::ParserError, StandardError
    false
  end
end
