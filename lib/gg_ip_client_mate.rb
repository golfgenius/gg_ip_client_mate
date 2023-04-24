# frozen_string_literal: true

require_relative 'gg_ip_client_mate/version'

#
# A gem serving as a wrapper over Golf Genius Identity Provider setup
# to make intagration more simple.
#
module GgIpClientMate
  def self.authorization_uri
    Oauth::OpenIdConnectClient.new(
      Config.client_identifier,
      Config.client_secret,
      Config.redirect_uri,
      Config.oauth_provider_uri
    ).authorization_uri
  end
end

require 'gg_ip_client_mate/config'
require 'oauth/oauth'
