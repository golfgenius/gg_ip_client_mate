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
  # Custom InvalidRequestError error class
  #
  # @param [String] message - the error message
  #
  # Returns an error message describing the problem.
  #
  class InvalidRequestError < StandardError; end

end
