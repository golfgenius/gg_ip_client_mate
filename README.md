# GgIpClientMate

The purpose of this gem is to simplify integration with Golf Genius Identity Provider setup by acting as a wrapper.

## Installation

Install the gem and add to the application's Gemfile:
```ruby
  gem 'gg_ip_client_mate', git: 'https://github.com/golfgenius/gg_ip_client_mate', branch: 'master'
```
Generate a github token from https://github.com/settings/tokens with `repo` scope, copy the code and add it to the bundle config `bundle config GITHUB__COM my-token:x-oauth-basic` where `my-token` is the new token generated from Git

Then run `bundle install`

Initialize GgIpClientMate config variables:
```ruby
  GgIpClientMate::Config.client_identifier = Rails.application.secrets["oauth_client_id"] # This variable is used to set the OAuth client ID provided by the IP application. It is typically used to authenticate the client application with the IP.
  GgIpClientMate::Config.client_secret = Rails.application.secrets["oauth_client_secret"] # This variable is used to set the OAuth client secret provided by the IP application. It is typically used in conjunction with the client ID to authenticate the client application with the IP.
  GgIpClientMate::Config.oauth_provider_uri = Rails.application.secrets["oauth_provider_uri"] # This variable is used to set the URI for the IP application, which is used to initiate the OAuth authentication flow. This URI should have an HTTPS prefix for security reason

  GgIpClientMate::Config.redirect_uri = '...' # This variable is used to set the URI where the IP application will redirect the user after they have authenticated and granted access to their information. This URI should be responsible for exchanging the IP code for a user token and refresh token.
  GgIpClientMate::Config.root_uri = '...' #  This variable is used to set the root URI for the client application, which is where the user will be redirected after logging out of the IP application.

  GgIpClientMate::Config.oauth_token_attribute_name = '...' # This variable represents the attribute name on User model that is used to store an access token that is issued by an OAuth provider to authorize third-party applications in order to access a user's protected resources.
  GgIpClientMate::Config.oauth_refresh_token_attribute_name = '...' # This variable represents the attribute name that is used to store the refresh_token that needed to obtain a new access token when the current access token expires in OAuth authentication.
  GgIpClientMate::Config.external_id_attribute_name = '...'  # This variable represents the attribute name used to link a user on the client application with the corresponding user on the identity provider application( external_id )
  GgIpClientMate::Config.user_info_attribute_mapping = { ... } # This variable represents a hash used for mapping all the user attributes with the doorkeeper attributes
```

The recommended way to initialize GgIpClientMate config variables is to create a new file inside the config/initializers directory. You can name it anything you like, for example, `gg_ip_client_mate_config.rb`.
Inside the initializer file, you need to add the necessary configurations. However, it's **_important_** to note that the initializer does not have direct access to the application routes. To overcome this, you should initialize the configurations within a `Rails.application.config.after_initialize` block. Here's an example:
```ruby
Rails.application.config.after_initialize do
  Rails.application.reload_routes!

  GgIpClientMate::Config.redirect_uri = Rails.application.routes.url_helpers.oauth_login_url
  GgIpClientMate::Config.root_uri = Rails.application.routes.url_helpers.root_url
end
```
Feel free to modify these configurations based on your specific needs.

## Usage

#### Authorization uri
Get the IP authorization URI for the Client with the given scope using:
```ruby
  GgIpClientMate.authorization_uri
```
Then redirect the flow to the result url provided by `GgIpClientMate.authorization_uri`

#### Get Token from Code
Retrieve the user token and refresh token from an authorization code received from an OAuth2 authentication flow.
In the controller method that is responsible for IP login add this in order to exchange the authorization code for an access token and refresh token.
```ruby
  GgIpClientMate.get_token_from_code(params[:code])
```

#### Get IP user details and update the database record
Find and update or create a user record in the local application database based on information obtained from the IP. This method is used to get latest data about the User from IP ( the single source of truth )
```ruby
  GgIpClientMate.find_and_update_or_create_user(token_and_refresh: token_and_refresh)
```

Two methods that need to be implemented on the User model in order to make `find_and_update_or_create_user` functionality work. Let's break down each method and its purpose:
1. `assign_attributes_and_association_attributes` method:
  - This method is responsible for assigning doorkeeper attributes to a user instance. It takes a details parameter, which is a hash containing attribute-value pairs.
  - Example 1: If all attributes are present on the user model. In this case, the method simply assigns the attributes using the assign_attributes method, which is a built-in Rails method for mass assignment.
  ```ruby
    def assign_attributes_and_association_attributes(details)
      assign_attributes(details)
    end
  ```
  - Example 2: If the user model has other model associations. In this scenario, the method handles assigning attributes to each association separately. It iterates over the details hash, checking if each key starts with a specific prefix ex('profile_'). If it does, it extracts the attribute name by removing the prefix and assigns the value to association. This way, the method separates user attributes from association attributes.
  ```ruby
    def assign_attributes_and_association_attributes(details)
      user_details = {}
      profile_details = {}
      details.each do |key, value|
        if key.start_with? 'profile_'
          profile_key = key.to_s.delete_prefix('profile_')
          profile_details[profile_key] = value
        else
          user_details[key] = value
        end
      end

      build_profile if profile.blank?
      profile.assign_attributes(profile_details)
      assign_attributes(user_details)
    end
  ```

2. `save_with_associations` method:
  - This method is responsible for saving the user instance and all its associations. It ensures that when the user is saved, any associated models (such as a profile) are also saved.
  - Its purpose is to handle the saving process for the user and its associations.

#### Update Source
When updating User details from the client app, the client need to send the latest changes to the IP. Add this to the user update controller action
```ruby
  GgIpClientMate.update_source(user)
```

If client allows to change user avatar, then when avatar gets changed, the client needs to call this action
```ruby
  GgIpClientMate.update_source(user, avatar_changed: true)
```

#### Update Password
When updating User password from the client app, the client need to check that current password is valid, and after that update password on IP
```ruby
  GgIpClientMate.update_password(user, new_password, password_confirmation, password)
```

#### Revoke existing session and logout user from client app and from IP
When a user wants to log out of the client application, before clearing the cookie, the token and refresh token needs to be revoked and the IP session needs to be destroyed
Add this to the session destroy controler action
```ruby
GgIpClientMate.revoke(current_user) # to revoke token and refresh token
redirect_to GgIpClientMate.logout_url # to redirect to the IP logout URL
```
After user gets logged out of the IP, he will get redirected back to client app route path.


### Webhook functionality
When IP or other clients perform updates on any User instances, the IP application sends HTTPS requests to all active webhook instances.
Client applications need to check that a webhook comes from a valid source. In this case each webhook request should include a 'IP-Signature' header and the signature should be valid. Then, only if valid signature, clients can react to the webhooks accordingly.
Each webhook request has an `action_type` field attached to it. Client application should react to webhook requests based on this field.

#### Webhook config
The Identity Provider generates a `webhook_secret_key` or signing key known only by the client application and the webhook provider. This secret is utilized to create a digital signature for each webhook payload.
Additionally a webhook event should be handeled within a specific time. This is called `webhook_tolerance`.

Add this to your initializers:
```ruby
# Webhook requests
GgIpClientMate::Config.webhook_tolerance = X # an integer representing the tolerance minutes. Webhooks that were sent before X.minutes ago will not be resolved
GgIpClientMate::Config.webhook_secret_key = Rails.application.secrets['webhook_secret'] # string generated by IP when webhook event is added
```

#### Verify Webhook Signature
Client applications are responsible for verifying incoming webhook payloads by comparing the received signature with the signature generated using the secret.
The signature will contain event data encrypted using the `webhook_secret_key`. This creates a unique HMAC (Hash-based Message Authentication Code) signature for the event data. The signature is included in the headers of the HTTP POST request sent to client applications. IP app leverages the [Stripe webhook signing algorithm](https://stripe.com/docs/webhooks#verify-manually) for this functionality.

Add this line to the client webhook handler controller action:
```ruby
GgIpClientMate.validate_webhook_signature!(request) # returns true if signature is valid or raise error:
# raises GgIpClientMate::InvalidWebhookSignatureError when signature is missing or invalid
# raises GgIpClientMate::InvalidWebhookTimestampError when the timestamp exceeds the specified webhook tolerance(GgIpClientMate::Config.webhook_tolerance)
```

#### React to "user_updated" webhook
When webhoook `action_type` is `user_updated`, a client application has the responsability of fetching the latest user data from IP app

Add this line to the client webhook handler to get latest user info fields:
```ruby
user_details = GgIpClientMate.fetch_user_info_for_webhook(user_id, webhook_id) # returns json field with lates user data
# raises GgIpClientMate::InvalidWebhookUserInfoRequestError with a message in case IP encountered an error in returning user data

user.assign_attributes(GgIpClientMate.user_attributes(user_details)) # GgIpClientMate.user_attributes maps IP user attributes to client application user attributes
# save or update user
```
