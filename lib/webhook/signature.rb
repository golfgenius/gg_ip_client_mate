#
# Webhook class is responsible for validating the incoming webhook reqests.
# The Webhook class checks the authenticity and integrity of these notifications
# by verifying the IP-Signature header.
#
module Webhook
  #
  # The Signature class is responsible for validating and signing requests
  #
  class Signature
    #
    # validate_webhook_signature! Ensures that a webhook request is valid by:
    #
    # ensuring that the timestamp in the request's headers is recent enough
    # to prevent replay attacks. It raises InvalidWebhookTimestampError
    # error if the timestamp exceeds the agreed tolerance
    #
    # verifying the authenticity of the request by calculating and comparing
    # the expected signature with the one provided in the request.
    # If the signatures do not match, it raises an InvalidWebhookTimestampError
    #
    def self.validate_webhook_signature!(request, special_signing_key)
      signature = request.headers['IP-Signature']

      raise ::GgIpClientMate::InvalidWebhookSignatureError if signature.blank?

      signed_at_timestamp = header_timestamp(signature)

      webhook_tolerance = GgIpClientMate::Config.webhook_tolerance.to_i
      raise ::GgIpClientMate::InvalidWebhookTimestampError if signed_at_timestamp < webhook_tolerance.minutes.ago

      expected_signature = hexdigest(
        special_signing_key.presence || GgIpClientMate::Config.webhook_secret_key,
        signature_string(signed_at_timestamp, JSON.parse(request.body.to_json).first)
      )

      raise ::GgIpClientMate::InvalidWebhookSignatureError if signed_payload(signature) != expected_signature

      true
    end

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

    def self.header_signature_values(signature)
      signature.split(',')
    end

    def self.header_timestamp(signature)
      unix_timestamp = header_signature_values(signature).first.split('=').last.to_i

      Time.at(unix_timestamp).utc
    end

    def self.signed_payload(signature)
      header_signature_values(signature).last.split('=').last
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
