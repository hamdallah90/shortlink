# frozen_string_literal: true

require "securerandom"

class ShortCodeGenerator
  DEFAULT_LENGTH = 10

  def initialize(algorithm:, length: DEFAULT_LENGTH)
    @algorithm = algorithm.to_s
    @length = length.to_i
  end

  def generate(url, attempt: 0)
    return SecureRandom.alphanumeric(@length) if @algorithm == "random"

    SecureRandom.alphanumeric(@length)
  end
end
