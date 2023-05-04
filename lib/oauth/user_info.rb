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
      response = HTTParty.get(
        OpenIdConnectClient.discover.userinfo_endpoint,
        headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{token}" }
      )

      return JSON.parse(response.body) if response.code == 200
    end

    #
    # This get_new_token_and_refresh method obtains a new access token and refresh
    # token pair from IP using the user's existing refresh token.
    #
    # @param [Object] user - object representing the user whose access token needs
    # to be refreshed
    #
    # If the request is successful, the method returns a hash containing two keys:
    # user_token and user_refresh_token. The value of the user_token key is the
    # new access token obtained from the IP, while the value of the user_refresh_token
    # key is the new refresh token obtained from the OIDC provider.
    #
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

    #
    # The update_existing_user method updates an existing user record in the local application
    # database with the latest token and refresh token information obtained from an IP and
    # user information associated with the user's IP account, keeping the local application's
    # user records up-to-date with the latest information from an IP.
    #
    # @param [Object] user - object representing the user
    # @param [Hash] token_and_refresh - hash thant contains token and refresh token
    # @param [Hash] user_info - hash thant contains all user information from IP
    #
    # This method returns updated user record
    #
    def self.update_existing_user(user, token_and_refresh, user_info)
      user.assign_attributes(user_attributes(user_info, token_and_refresh))
      user.save!

      user
    end

    #
    # The user_create_or_update_with_associations method creates or updates a user record in the 
    # local application database with the latest token and refresh token information obtained
    # from an IP and user information associated with the user's IP account.
    #
    # @param [Object] user - object representing the user
    # @param [Hash] token_and_refresh - hash thant contains token and refresh token
    # @param [Hash] user_info - hash thant contains all user information from IP
    #
    # This method returns updated user record
    #
    def self.user_create_or_update_with_associations(user, token_and_refresh, user_info)
      return if user_info.blank?

      user = if user.present?
              update_existing_user(user, token_and_refresh, user_info)
            else
              User.create(user_attributes(user_info, token_and_refresh))
            end

      user&.reload
    end

    #
    # The user_attributes method constructs a hash of attributes that can be used to
    # create or update a user record in the local application database based on the
    # user information and token and refresh token information obtained from IP.
    #
    # @param [Hash] user_info - hash thant contains all user information from IP
    # @param [Hash] token_and_refresh - hash thant contains token and refresh token
    #
    # This method returns a hash, which contains the values of all the attributes
    # needed to create or update a user record in the local application database
    # based on the latest information obtained from the IP.
    #
    def self.user_attributes(user_info, token_and_refresh)
      attrs = {
        GgIpClientMate::Config.oauth_token_attribute_name => token_and_refresh[:user_token],
        GgIpClientMate::Config.oauth_refresh_token_attribute_name => token_and_refresh[:user_refresh_token],
      }

      GgIpClientMate::Config.user_info_attribute_mapping.each do |key, doorkeeper_key|
        attrs[key] = user_info[doorkeeper_key]
      end

      attrs
    end

    #
    #
    #
    # def self.update_source(user, async: false)
    #   payload = {
    #     first_name: user.first_name,
    #     last_name: user.last_name,
    #     gender: user.gender,
    #     phone: user.phone,
    #     phone_prefix: user.phone_prefix,
    #     phone_prefix_country: user.phone_prefix_country,
    #     ghin_number: user.ghin_number
    #   }

    #   # if async
    #   #   PerformHttpRequest.perform_async(action: :patch, url: , body: payload.to_json, headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{user.oauth_token}" })
    #   #   HTTParty.patch(
    #   #     "#{Rails.application.secrets["ip_root_url"]}/api/update_account_settings",
    #   #     body: payload.to_json,
    #   #     headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{user.oauth_token}" }
    #   #   )
    #   # else
    #     @response = HTTParty.patch(
    #       "#{Rails.application.secrets["ip_root_url"]}/api/update_account_settings",
    #       body: payload.to_json,
    #       headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{user.oauth_token}" }
    #     )
    #   # end
    # end
  end
end
