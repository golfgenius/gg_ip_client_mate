# frozen_string_literal: true

require_relative 'gg_ip_client_mate/version'

#
# A gem serving as a wrapper over Golf Genius Identity Provider setup
# to make intagration more simple.
#
module GgIpClientMate
  def self.authorization_uri(client_identifier, client_secret, redirect_uri, oauth_provider_uri)
    Oauth::OpenIdConnectClient.new(
      client_identifier,
      client_secret,
      redirect_uri,
      oauth_provider_uri
    ).authorization_uri
  end
end

require 'oauth/oauth'
