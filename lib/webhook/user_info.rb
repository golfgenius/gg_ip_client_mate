#
# Webhook::UserInfo class is responsible for fetching latest user info for the incoming webhook reqest
#
module Webhook
  class UserInfo
    #
    # The fetch_user_info_for_webhook requests the latest user details from IP using
    # GET request to the /api/userinfo endpoint with the user_id and webhook_id
    #
    # @param [Integer] user_id - number representing the IP user id, or
    #                           client application user external id
    # @param [Integer] webhook_id - IP webhook id that is used to validate
    #                             request signature
    #
    # This method returns the result of the HTTP request or raises error if the request failed
    #
    def self.fetch_user_info_for_webhook(user_id, webhook_id)
      payload = {
        uid: GgIpClientMate::Config.client_identifier,
        webhook_id: webhook_id.to_s,
        user_id: user_id.to_s
      }

      response = HTTParty.get(
        "#{GgIpClientMate::Config.oauth_provider_uri}/api/userinfo",
        query: payload,
        headers: { 'Content-Type' => 'application/json', 'IP-Signature' => GgIpClientMate.sign_request(payload.to_json) }
      )

      raise ::GgIpClientMate::InvalidWebhookUserInfoRequestError.new(message: response['error']) unless response.success?

      response
    end
  end
end
