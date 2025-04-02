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
      if app_caching_enabled?
        Rails.cache.fetch(discovery_cache_key, expires_in: 24.hours.to_i) do
          discover!
        end
      else
        @discover ||= discover!
      end
    end

    #
    # Checks if application caching is enabled.
    #
    # This method determines whether caching is enabled in the client application
    # by checking the Rails configuration for action controller caching.
    #
    # @return [Boolean] true if caching is enabled, false otherwise.
    #
    def self.app_caching_enabled?
      Rails.application.config.action_controller.perform_caching
    end

    #
    # Generates a unique cache key for storing the OpenID Connect discovery configuration.
    #
    # This key is used when caching the discovery response to avoid redundant
    # network requests and improve performance.
    #
    # @return [Array<String>] An array containing the cache key identifier
    #                         and the client identifier.
    #
    def self.discovery_cache_key
      ['idp_discovery', GgIpClientMate::Config.client_identifier]
    end

    #
    # Performs OpenID Connect provider discovery.
    #
    # This method fetches the provider configuration for the given OAuth provider URI
    # and returns an instance of OpenIDConnect::Discovery::Provider::Config.
    #
    # @return [OpenIDConnect::Discovery::Provider::Config] The discovered provider configuration.
    #
    def self.discover!
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
    def revoke(user, api_session_revoke: false)
      api_session_revoke ? api_sign_out(user) : revoke_current_token(user)
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

    #
    # The api_sign_out method is a private method that calls an API endpoint in order
    # to revoke the user session from Identiy Provider. This can be done only because
    # IP stores session on the server side.
    #
    # This method returns the response of the API request -> 204 no content status
    def api_sign_out(user)
      HTTParty.send(
        :delete,
        "#{GgIpClientMate::Config.oauth_provider_uri}/api/auth/sign_out",
        headers: {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{user.oauth_token}"
        }
      )
    end

    #
    # The revoke_current_token method is a private method that calls an API endpoint
    # in order to revoke the user dorkeeper token + refresh token.
    #
    # This method returns the response of the API request => 200 status code, json: {}
    def revoke_current_token(user)
      revocation_endpoint = discover&.raw.try(:[], 'revocation_endpoint')

      HTTParty.send(
        :post,
        revocation_endpoint,
        body: {
          token: user.oauth_token,
          client_id: GgIpClientMate::Config.client_identifier,
          client_secret: GgIpClientMate::Config.client_secret
        }.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{user.oauth_token}"
        }
      )
    end
  end
end
