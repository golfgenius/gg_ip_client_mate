#
# Webhook class is responsible for validating the incoming webhook reqests.
# The Webhook class checks the authenticity and integrity of these notifications
# by verifying the IP-Signature header.
#
module Webhook
  #
  # The SignatureValidator class is responsible for validating the signature of an
  # incoming webhook request.
  #
  class SignatureValidator
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
    def self.validate_webhook_signature!(request)
      body_json = JSON.parse(request.body.to_json).first

      raise ::GgIpClientMate::InvalidWebhookSignatureError if request.headers['IP-Signature'].blank?

      header_signature_values = request.headers['IP-Signature'].split(',')
      signed_at_timestamp = Time.at(header_signature_values.first.split('=').last.to_i).utc

      webhook_tolerance = GgIpClientMate::Config.webhook_tolerance.to_i
      raise ::GgIpClientMate::InvalidWebhookTimestampError if signed_at_timestamp < webhook_tolerance.minutes.ago

      webhook_signed_value = header_signature_values.last.split('=').last
      digest = OpenSSL::Digest.new('sha256')
      expected_signature = OpenSSL::HMAC.hexdigest(
        digest,
        GgIpClientMate::Config.webhook_secret_key,
        "#{signed_at_timestamp}.#{body_json}"
      )

      raise ::GgIpClientMate::InvalidWebhookSignatureError if webhook_signed_value != expected_signature

      true
    end
  end
end
