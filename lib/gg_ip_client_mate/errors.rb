# frozen_string_literal: true

module GgIpClientMate
  #
  # Custom InvalidAuthorizationGrant error class
  #
  # @param [String] message - the error message
  #
  # Returns an error message describing the problem.
  #
  class InvalidAuthorizationGrantError < StandardError
    def message
      'The provided authorization grant is invalid, expired, revoked, ' \
        'does not match the redirection URI used in the authorization request, ' \
        'or was issued to another client. Please sign in again.'
    end
  end

  #
  # Custom InvalidRequestTimestampError error class
  # Returns an error message describing that the timestamp exceds the agreed tolerance
  #
  class InvalidRequestTimestampError < StandardError
    def message
      'The request timestamp exceds the agreed tolerance.'
    end
  end

  #
  # Custom InvalidRequestSignatureError error class
  # Returns an error message describing that the timestamp exceds the agreed tolerance
  #
  class InvalidRequestSignatureError < StandardError
    def message
      'The request signature is not valid.'
    end
  end

  #
  # Custom InvalidRequestUserInfoRequestError error class
  # Returns an error message describing why user info request failed
  #
  class InvalidRequestUserInfoRequestError < StandardError
  end

end
