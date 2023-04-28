# frozen_string_literal: true

require 'httparty'

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
  class UserInfo
    #
    #
    #
    def self.info(token)
      response = HTTParty.get(
        ::OpenIdConnectClient.discover.userinfo_endpoint,
        headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{token}" }
      )

      return JSON.parse(response.body) if response.code == 200
    end

    def self.get_new_token_and_refresh(user)
      response = HTTParty.post(
        ::OpenIdConnectClient.discover.token_endpoint,
        headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
        body: "grant_type=refresh_token&client_id=#{GgIpClientMate::Config.client_identifier}&client_secret=#{GgIpClientMate::Config.client_secret}&refresh_token=#{user.send(GgIpClientMate::Config.oauth_refresh_token_attribute_name)}"
      )

      response_body = JSON.parse(response.body)
      {
        user_token: response_body['access_token'],
        user_refresh_token: response_body['refresh_token']
      }
    end

    #
    #
    #
    def self.find_and_update_or_create_user(token_and_refresh: {}, user: nil)
      if user.present? && token_and_refresh.blank?
        token_and_refresh = {
          user_token: user.send(GgIpClientMate::Config.oauth_token_attribute_name),
          user_refresh_token: user.send(GgIpClientMate::Config.oauth_refresh_token_attribute_name)
        }
      end

      user_info = info(token_and_refresh[:user_token])

      if user_info.present?
        user = User.find_by(GgIpClientMate::Config.external_id_attribute_name => user_info['sub'])
      elsif user.present?
        token_and_refresh = get_new_token_and_refresh(user)
        user_info = info(token_and_refresh[:user_token])
      end

      user_create_or_update_with_associations(user, token_and_refresh, user_info) unless user.blank? && user_info.blank?
    end
  end

  def self.update_existing_user(user, token_and_refresh, user_info)
    user.assign_attributes(user_attributes(user_info, token_and_refresh))
    user.save!

    user
  end

  def self.user_create_or_update_with_associations(user, token_and_refresh, user_info)
    return if user_info.blank?

    user = if user.present?
             update_existing_user(user, token_and_refresh, user_info)
           else
             User.create(user_attributes(user_info, token_and_refresh))
           end

    user&.reload
  end

  def self.user_attributes(user_info, token_and_refresh)
    attrs = {
      user.send(GgIpClientMate::Config.oauth_token_attribute_name) => token_and_refresh[:user_token],
      user.send(GgIpClientMate::Config.oauth_refresh_token_attribute_name) => token_and_refresh[:user_refresh_token],
    }

    GgIpClientMate::Config.each do |key, doorkeeper_key|
      attrs[key] = user_info[doorkeeper_key]
    end

    attrs
  end
end
