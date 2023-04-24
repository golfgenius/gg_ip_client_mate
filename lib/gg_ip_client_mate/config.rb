# frozen_string_literal: true

module GgIpClientMate
  #
  #  Used to store configuration settings for an Identity Provider Client,
  # such as the client identifier, client secret, redirect URI, and
  # OAuth provider URI.
  #
  # Set config settings like so:
  # GgIpClientMate::Config.client_identifier = 'your-client-id'
  #
  class Config
    @client_identifier, @client_secret, @redirect_uri, @oauth_provider_uri = nil

    class << self
      attr_accessor :client_identifier, :client_secret, :redirect_uri, :oauth_provider_uri
    end
  end
end
