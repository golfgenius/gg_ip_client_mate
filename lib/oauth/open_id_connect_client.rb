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
    # supports the OpenID Connect protocol.
    #
    # The discover method returns an instance of OpenIDConnect::Discovery::Provider::Config
    # that contains the discovered OpenID Connect provider configuration.
    #
    def self.discover(oauth_provider_uri)
      OpenIDConnect::Discovery::Provider::Config.discover! oauth_provider_uri
    end

    private

    #
    # The discover method is a private method that discovers the OpenID Connect
    # provider configuration from the provided OAuth provider URI.
    #
    # The discover method returns an instance of OpenIDConnect::Discovery::Provider::Config
    # that contains the discovered OpenID Connect provider configuration.
    def discover
      @discover ||= self.class.discover(GgIpClientMate::Config.oauth_provider_uri)
    end
  end
end
