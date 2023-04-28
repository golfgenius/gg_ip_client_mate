# frozen_string_literal: true

require_relative 'gg_ip_client_mate/version'

#
# A gem serving as a wrapper over Golf Genius Identity Provider setup
# to make intagration more simple.
#
module GgIpClientMate
  def self.authorization_uri
    Oauth::OpenIdConnectClient.new.authorization_uri
  end

  def self.get_token_from_code(code)
    Oauth::OpenIdConnectClient.new.get_token_from_code(code)
  end

  def self.find_and_update_or_create_user(token_and_refresh: {}, user: nil)
    Oauth::UserInfo.find_and_update_or_create_user(token_and_refresh: token_and_refresh, user: user)
  end
end

require 'gg_ip_client_mate/config'
require 'oauth/oauth'
