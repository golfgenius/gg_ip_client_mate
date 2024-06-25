# frozen_string_literal: true

require_relative 'gg_ip_client_mate/version'

#
# A gem serving as a wrapper over Golf Genius Identity Provider setup
# to make intagration more simple.
#
module GgIpClientMate
  #
  # The authorization_uri method generates the authorization URI for the
  # OpenID Connect client with the given scope.

  # The authorization_uri method returns a string containing the authorization
  # URI for the OpenID Connect client with the given scope.
  #
  def self.authorization_uri
    Oauth::OpenIdConnectClient.new.authorization_uri
  end

  #
  # This get_token_from_code retrieves the user token and refresh token
  # from an authorization code received from an OAuth2 authentication flow.
  # The method uses the Rack::OAuth2 client library to exchange the
  # authorization code for an access token and refresh token.
  #
  # @param [String] code - representing the authorization code received
  #                        from the authorization server.
  #
  # This method returns:
  #     - If the exchange is successful, the method returns a hash containing the user token and refresh token:
  #         * user_token: A string representing the user token.
  #         * user_refresh_token: A string representing the user refresh token.
  #
  #     - If the exchange is unsuccessful, the method returns nil.
  #
  def self.get_token_from_code(code)
    Oauth::OpenIdConnectClient.new.get_token_from_code(code)
  end

  #
  # The info method makes a request to an OpenID Connect provider's userinfo
  # endpoint to retrieve information about the user associated with the
  # provided access token.
  #
  # @param [String] token - the access token provided by the IP application
  #
  # If the response from the userinfo endpoint has a status code of 200,
  # the method returns a parsed JSON object representing the user information.
  # Otherwise, the method returns nil.
  #
  def self.info(token)
    Oauth::UserInfo.info(token)
  end

  #
  # The find_and_update_or_create_user method finds or creates a user record in the
  # local application database based on information obtained from the IP.
  #
  # @param [Hash] token_and_refresh - hash thant contains token and refresh token
  # @param [Object] user - object representing the user
  #
  # If a user object is provided and token_and_refresh is not, the method will attempt
  # to retrieve the user's access token and refresh token from the user object and
  # populate the token_and_refresh parameter accordingly. This assumes that the user
  # object has already been authenticated with the IP and has valid tokens
  # associated with it.
  #
  # The method returns the updated or newly created user object, or nil if no user object
  # is found or created.
  #
  def self.find_and_update_or_create_user(token_and_refresh: {}, user: nil)
    Oauth::UserInfo.find_and_update_or_create_user(token_and_refresh: token_and_refresh, user: user)
  end

  #
  # The update_source method updates the user account settings in the IP by sending a
  # PATCH request to the /api/update_account_settings endpoint with the updated payload
  #
  # @param [Object] user - object representing the user
  # @param [Boolean] avatar_changed - optional - true when avatar is changed
  #
  # This method returns the result of the HTTP request
  #
  def self.update_source(user, avatar_changed: false)
    Oauth::UserInfo.update_source(user, avatar_changed: avatar_changed)
  end

  #
  # The update_password method updates user's password using an IP API
  #
  # user [Object] user - object representing the user
  # new_password [String]- The new password to be set.
  # password_confirmation [String]- The confirmation of the new password.
  # password [String] - The current password for authentication.
  #
  # Returns a Hash containing the response code and error message, if any.
  #
  def self.update_password(user, new_password, password_confirmation, password)
    Oauth::UserInfo.update_password(user, new_password, password_confirmation, password)
  end

  #
  # This method revokes an OAuth token for a given user. It sends a revocation
  # request to the revocation endpoint of an OAuth provider to invalidate the
  # token.
  #
  # @param [Object] user - representing the user for whom the OAuth token should
  #                        be revoked. The user object must have an oauth_token
  #                        attribute containing the OAuth token to be revoked.
  # @param [Boolean] api_session_revoke - optional - true when client opts for
  #                               session destroy using API request instead
  #                               of redirect the flow to the IP logout URL
  #
  # This method returns the result of the HTTP request
  #
  def self.revoke(user, api_session_revoke: false)
    Oauth::OpenIdConnectClient.new.revoke(user, api_session_revoke: api_session_revoke)
  end

  #
  # This method returns the Doorkeeper logout url needed for client applications
  # in order to fully logout from the application and IP
  #
  def self.logout_url
    Oauth::OpenIdConnectClient.new.logout_url
  end

  #
  # This method is responsible for validating the signature of a webhook request.
  #
  # @param [Object] request - representing the webhook request that will be
  #                           validated
  # @param [Object] payload - custom payload to test the signature
  # @param [String] special_signing_key - optional - key for signing requests
  #                       other than GgIpClientMate::Config.webhook_secret_key
  #
  # The method returns:
  #   - true if webhook signature is valid
  #   - raises exception that includes the signature validation issue
  #
  def self.validate_webhook_signature!(request, payload: nil, special_signing_key: nil)
    special_signing_key = special_signing_key.presence || GgIpClientMate::Config.webhook_secret_key
    payload ||= JSON.parse(request.body.to_json).first
    Webhook::Signature.validate_webhook_signature!(request, payload, special_signing_key)
  end

  #
  # This method is responsible for creating a signature string based on the payload
  # provided and a special key needed for encryption
  #
  # @param [Object] payload - representing the payload for the furure request
  #
  # @param [String] special_signing_key - optional - key for signing requests
  #                       other than GgIpClientMate::Config.webhook_secret_key
  #
  # This method returns a tring representing the signature for the future request
  #
  def self.sign_request(payload, special_signing_key: nil)
    special_signing_key = special_signing_key.presence || GgIpClientMate::Config.webhook_secret_key
    Webhook::Signature.sign_request(payload, special_signing_key)
  end

  #
  # The fetch_user_info_for_webhook requests the latest user details from IP using
  # GET request to the /api/userinfo endpoint with the user_id and webhook_id
  #
  # @param [Integer] user_id - number representing the IP user id, or
  #                           client application user external id
  # @param [Integer] webhook_id - IP webhook id that is used to validate
  #                             request signature
  #
  # This method returns the result of the HTTP request or raises error if the request failed
  #
  def self.fetch_user_info_for_webhook(user_id, webhook_id)
    Webhook::UserInfo.fetch_user_info_for_webhook(user_id, webhook_id)
  end

  #
  # The user_attributes method constructs a hash of attributes that can be used to
  # create or update a user record in the local application database based on the
  # user information and token and refresh token information obtained from IP.
  #
  # @param [Hash] user_info - hash thant contains all user information from IP
  # @param [Hash] token_and_refresh - optional - hash thant contains token and
  #                                   refresh token
  #
  # This method returns a hash, which contains the values of all the attributes
  # needed to create or update a user record in the local application database
  # based on the latest information obtained from the IP.
  #
  def self.user_attributes(user_info, token_and_refresh = nil)
    Oauth::UserInfo.user_attributes(user_info, token_and_refresh)
  end
end

require 'gg_ip_client_mate/config'
require 'gg_ip_client_mate/errors'

require 'oauth/oauth'
require 'webhook/signature'
require 'webhook/user_info'
