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
    @client_identifier, @client_secret, @redirect_uri, @oauth_provider_uri, @root_uri = nil

    class << self
      ### IP config attributes
      attr_accessor :client_identifier, :client_secret, :oauth_provider_uri, :redirect_uri, :root_uri
      ########################

      ### User attributes
      # the attribute name on User model that is used to store an access token
      # that is issued by an OAuth provider to authorize third-party applications
      # to access a user's protected resources.
      attr_accessor :oauth_token_attribute_name

      # the attribute name that is used to store the refresh_token that needed to
      # obtain a new access token when the current access token expires in
      # OAuth authentication.
      attr_accessor :oauth_refresh_token_attribute_name

      # attribute name used to link a user on the client application with the
      # corresponding user on the identity provider application by providing
      # a unique identifier that can be used to retrieve and match user records.
      attr_accessor :external_id_attribute_name

      # attribute maps all the user attributes with the doorkeeper attributes
      attr_accessor :user_info_attribute_mapping

      ### Webhook attributes
      # attribute that stores an integer number representing the agreed tolerance
      # for webhook signature validation
      attr_accessor :webhook_tolerance

      # attribute that stores the webhook_secret_key that IP generates for each
      # client webhook instance
      attr_accessor :webhook_secret_key
    end
  end
end
