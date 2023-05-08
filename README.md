# GgIpClientMate

The purpose of this gem is to simplify integration with Golf Genius Identity Provider setup by acting as a wrapper.

## Installation

Install the gem and add to the application's Gemfile:
```
  gem 'gg_ip_client_mate', git: 'https://github.com/golfgenius/gg_ip_client_mate', branch: 'master'
```
Generate a github token from https://github.com/settings/tokens with `repo` scope, copy the code and add it to the bundle config `bundle config GITHUB__COM my-token:x-oauth-basic` where `my-token` is the new token generated from Git

Then run `bundle install`

Initialize GgIpClientMate config variables:
```
  GgIpClientMate::Config.client_identifier = Rails.application.secrets["oauth_client_id"] # This variable is used to set the OAuth client ID provided by the IP application. It is typically used to authenticate the client application with the IP.
  GgIpClientMate::Config.client_secret = Rails.application.secrets["oauth_client_secret"] # This variable is used to set the OAuth client secret provided by the IP application. It is typically used in conjunction with the client ID to authenticate the client application with the IP.
  GgIpClientMate::Config.oauth_provider_uri = Rails.application.secrets["oauth_provider_uri"] # This variable is used to set the URI for the IP application, which is used to initiate the OAuth authentication flow. This URI should have an HTTPS prefix for security reason
  GgIpClientMate::Config.redirect_uri ||= '...' # This variable is used to set the URI where the IP application will redirect the user after they have authenticated and granted access to their information. This URI should be responsible for exchanging the IP code for a user token and refresh token.
  GgIpClientMate::Config.root_uri ||= '...' #  This variable is used to set the root URI for the client application, which is where the user will be redirected after logging out of the IP application.
```

## Usage

#### Authorization uri
Get the IP authorization URI for the Client with the given scope using:
```
  GgIpClientMate.authorization_uri
```
Then redirect the flow to the result url provided by `GgIpClientMate.authorization_uri`

#### Get Token from Code
Retrieve the user token and refresh token from an authorization code received from an OAuth2 authentication flow.
In the controller method that is responsible for IP login add this in order to exchange the authorization code for an access token and refresh token.
```
  GgIpClientMate.get_token_from_code(params[:code])
```

#### Get IP user details and update the database record
Find and update or create a user record in the local application database based on information obtained from the IP. This method is used to get latest data about the User from IP ( the single source of truth )
```
  GgIpClientMate.find_and_update_or_create_user(token_and_refresh: token_and_refresh)
```

#### Update Source
When updating User details from the client app, the client need to send the latest changes to the IP. Add this to the user update controller action
```
  GgIpClientMate.update_source(user)
```

#### Revoke existing session and logout user from client app and from IP
When a user wants to log out of the client application, before clearing the cookie, the token and refresh token needs to be revoked and the IP session needs to be destroyed
Add this to the session destrio controler action
```
GgIpClientMate.revoke(current_user) # to revoke token and refresh token
redirect_to GgIpClientMate.logout_url # to redirect to the IP logout URL
```
After user gets logged out of the IP, he will get redirected back to client app route path.
