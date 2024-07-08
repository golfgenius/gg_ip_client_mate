#
# Security class is responsible for encrypting and validating the reqests.
#
module Security
  #
  # The Validator class is responsible for validating request signatures
  #
  class Validator
    #
    # validate_request_signature! Ensures that a request is valid by:
    #
    # ensuring that the timestamp in the request's headers is recent enough
    # to prevent replay attacks. It raises InvalidRequestTimestampError
    # error if the timestamp exceeds the agreed tolerance
    #
    # verifying the authenticity of the request by calculating and comparing
    # the expected signature with the one provided in the request.
    # If the signatures do not match, it raises an InvalidRequestTimestampError
    #
    def self.validate_request_signature!(request, payload, special_signing_key)
      signature = request.headers['IP-Signature']

      raise ::GgIpClientMate::InvalidRequestSignatureError if signature.blank?

      signed_at_timestamp = header_timestamp(signature)

      request_tolerance ||= (GgIpClientMate::Config.request_tolerance.presence || 5).to_i # minutes
      raise ::GgIpClientMate::InvalidRequestTimestampError if signed_at_timestamp < request_tolerance.minutes.ago

      expected_signature = Security::Encryptor.hexdigest(
        special_signing_key,
        Security::Encryptor.signature_string(signed_at_timestamp, payload)
      )

      raise ::GgIpClientMate::InvalidRequestSignatureError if signed_payload(signature) != expected_signature

      true
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
  end
end
