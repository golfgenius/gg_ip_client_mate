#
# Security class is responsible for encrypting and validating the reqests.
#
module Security
  #
  # The Encryptor class is responsible for encrypting requests
  #
  class Encryptor
    #
    # sign_request encrypts a request payload using a key
    # the encription is a hash-based message authentication code (HMAC) with SHA-256
    #
    # the signed request contains a timestamp and one signature that receiver must verify.
    # The timestamp is prefixed by `t=`, representing an Unix Time.
    # The signature is prefixed by `signed_payload=`.
    # The timestamp and signature are separated by a `,`.
    #
    def self.sign_request(payload, special_signing_key)
      timestamp = Time.current.utc
      payload = signature_string(timestamp, payload)
      signed_payload = hexdigest(special_signing_key, payload)

      "t=#{timestamp.to_i},signed_payload=#{signed_payload}"
    end

    def self.hexdigest(key, payload)
      OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new('sha256'),
        key,
        payload
      )
    end

    def self.signature_string(timestamp, payload)
      "#{timestamp}.#{payload}"
    end
  end
end
