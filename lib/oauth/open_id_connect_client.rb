# frozen_string_literal: true

require 'openid_connect'

#
# Open Authorization class widely used authentication and authorization
# protocol that enables third-party applications to access resources on behalf
# of a user, without needing to know the user's login credentials.
#
module Oauth
  #
  # Component that implements the OpenID Connect protocol on the client side.
  # Uses OAuth 2.0 and enables easy users to authenticate with Identity Provider
  # using their existing credentials.
  #
  class OpenIdConnectClient
    attr_reader :logout_url

    #
    # The initialize method creates a new instance of the class and initializes
    # it with the provided client identifier, client secret, and redirect URI.
    #
    # The initialize method returns a new instance of the OpenIdConnectClient class
    # with the OpenID Connect client initialized with the provided parameters.
    #
    def initialize
      @client = OpenIDConnect::Client.new(
        identifier: GgIpClientMate::Config.client_identifier,
        secret: GgIpClientMate::Config.client_secret,
        redirect_uri: GgIpClientMate::Config.redirect_uri,
        authorization_endpoint: discover&.authorization_endpoint,
        token_endpoint: discover&.token_endpoint,
        userinfo_endpoint: discover&.userinfo_endpoint
      )

      @logout_url = "#{discover.end_session_endpoint}?post_sign_out_redirect_url=#{GgIpClientMate::Config.root_uri}"
    end

    #
    # The authorization_uri method generates the authorization URI for the
    # OpenID Connect client with the given scope.

    # The authorization_uri method returns a string containing the authorization
    # URI for the OpenID Connect client with the given scope.
    #
    def authorization_uri
      @client.authorization_uri(scope: [:openid])
    end

    #
    # The discover method is a class method that discovers the OpenID Connect
    # provider configuration from the provided OAuth provider URI.
    #
    # @param [String] oauth_provider_uri - The URI of the OAuth provider that
    #                                      supports the OpenID Connect protocol.
    #
    # The discover method returns an instance of OpenIDConnect::Discovery::Provider::Config
    # that contains the discovered OpenID Connect provider configuration.
    #
    def self.discover
      OpenIDConnect::Discovery::Provider::Config.discover! GgIpClientMate::Config.oauth_provider_uri
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
    def get_token_from_code(code)
      @client.authorization_code = code

      begin
        access_token = @client.access_token!

        {
          user_token: access_token.access_token,
          user_refresh_token: access_token.refresh_token
        }
      rescue Rack::OAuth2::Client::Error
        nil
      end
    end

    def revoke(user)
      revocation_endpoint = discover&.raw.try(:[], 'revocation_endpoint')

      HTTParty.send(:post, revocation_endpoint, 
        body: {
          token: user.oauth_token,
          client_id: GgIpClientMate::Config.client_identifier,
          client_secret: GgIpClientMate::Config.client_secret
        }.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{user.oauth_token}"
        })
    end

    private

    #
    # The discover method is a private method that discovers the OpenID Connect
    # provider configuration from the provided OAuth provider URI.
    #
    # The discover method returns an instance of OpenIDConnect::Discovery::Provider::Config
    # that contains the discovered OpenID Connect provider configuration.
    def discover
      @discover ||= self.class.discover
    end
  end
end
