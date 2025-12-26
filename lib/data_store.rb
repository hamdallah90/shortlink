# frozen_string_literal: true

require "json"
require "fileutils"
require "thread"

class DataStore
  DEFAULT_STATE = {
    "short_to_url" => {},
    "url_to_short" => {}
  }.freeze
  MAX_ATTEMPTS = 10_000

  def initialize(path, generator:)
    @path = path
    @generator = generator
    @mutex = Mutex.new
    @state = {
      "short_to_url" => {},
      "url_to_short" => {}
    }
    load_state
  end

  def fetch_or_create(url)
    @mutex.synchronize do
      existing = @state["url_to_short"][url]
      return existing if existing

      short_code = next_code(url)
      @state["short_to_url"][short_code] = url
      @state["url_to_short"][url] = short_code
      persist_state

      short_code
    end
  end

  def find(short_code)
    @mutex.synchronize do
      @state["short_to_url"][short_code]
    end
  end

  private

  def next_code(url)
    attempts = 0

    loop do
      raise "Unable to generate unique short code" if attempts > MAX_ATTEMPTS

      candidate = @generator.generate(url, attempt: attempts)
      existing_url = @state["short_to_url"][candidate]
      return candidate if existing_url.nil? || existing_url == url

      attempts += 1
    end
  end

  def load_state
    return unless File.exist?(@path)

    raw = File.read(@path)
    return if raw.strip.empty?

    parsed = JSON.parse(raw)
    @state = DEFAULT_STATE.merge(parsed)
  rescue JSON::ParserError
    raise "Data store file is corrupted: #{@path}"
  end

  def persist_state
    FileUtils.mkdir_p(File.dirname(@path))
    temp_path = "#{@path}.tmp"
    File.write(temp_path, JSON.generate(@state))
    File.rename(temp_path, @path)
  end
end
