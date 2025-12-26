# frozen_string_literal: true

require "base64"
require "openssl"
require "securerandom"

class KeyedCipher
  ALGORITHM = "aes-256-gcm"
  IV_LENGTH = 12
  TAG_LENGTH = 16

  def initialize(secret)
    @key = OpenSSL::Digest::SHA256.digest(secret.to_s)
  end

  def encode(plaintext)
    cipher = OpenSSL::Cipher.new(ALGORITHM).encrypt
    cipher.key = @key
    iv = SecureRandom.random_bytes(IV_LENGTH)
    cipher.iv = iv

    ciphertext = cipher.update(plaintext) + cipher.final
    tag = cipher.auth_tag(TAG_LENGTH)

    Base64.urlsafe_encode64(iv + tag + ciphertext, padding: false)
  end

  def decode(token)
    raw = Base64.urlsafe_decode64(token.to_s)
    return nil if raw.bytesize <= IV_LENGTH + TAG_LENGTH

    iv = raw.byteslice(0, IV_LENGTH)
    tag = raw.byteslice(IV_LENGTH, TAG_LENGTH)
    ciphertext = raw.byteslice(IV_LENGTH + TAG_LENGTH, raw.bytesize - IV_LENGTH - TAG_LENGTH)

    cipher = OpenSSL::Cipher.new(ALGORITHM).decrypt
    cipher.key = @key
    cipher.iv = iv
    cipher.auth_tag = tag

    cipher.update(ciphertext) + cipher.final
  rescue ArgumentError, OpenSSL::Cipher::CipherError
    nil
  end
end
