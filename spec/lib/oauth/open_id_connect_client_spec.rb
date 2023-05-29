RSpec.describe Oauth::OpenIdConnectClient do
  before do
    GgIpClientMate::Config.client_identifier = 'customClientIdentifier'
    GgIpClientMate::Config.client_secret = 'customClientSecret'
    GgIpClientMate::Config.oauth_provider_uri = 'https://test-identiy-provider.com'
    GgIpClientMate::Config.redirect_uri = 'http://test-client.com/oauth_login'
    GgIpClientMate::Config.root_uri = 'http://test-client.com'
  end

  describe '#authorization_uri' do
    it 'returns URL for the OpenID Connect client with the given scope' do
      VCR.use_cassette('openid_configuration') do
        expect(Oauth::OpenIdConnectClient.new.authorization_uri).to eql('https://test-identiy-provider.com/oauth/authorize?client_id=customClientIdentifier&redirect_uri=http%3A%2F%2Ftest-client.com%2Foauth_login&response_type=code&scope=openid')
      end
    end
  end

  describe '#discover' do
    it 'returns an instance of OpenIDConnect::Discovery::Provider::Config that contains the discovered OpenID Connect provider configuration' do
      VCR.use_cassette('openid_connect_discover') do
        discover = Oauth::OpenIdConnectClient.discover
        expect(discover).to be_a OpenIDConnect::Discovery::Provider::Config::Response
        expect(discover.authorization_endpoint).to eql 'https://test-identiy-provider.com/oauth/authorize'
        expect(discover.userinfo_endpoint).to eql 'https://test-identiy-provider.com/oauth/userinfo'
        expect(discover.token_endpoint).to eql 'https://test-identiy-provider.com/oauth/token'
        expect(discover.claims_supported).to eql %w[iss sub aud exp iat email first_name last_name phone phone_prefix phone_prefix_country gender ghin_number]
        expect(discover.end_session_endpoint).to eql 'https://test-identiy-provider.com/logout'
      end
    end
  end

  describe '#get_token_from_code' do
    it 'returns a hash containing the user token and refresh token when valid token' do
      VCR.use_cassette('get_token_from_code') do
        token_and_refresh = Oauth::OpenIdConnectClient.new.get_token_from_code('customC0de')
        expect(token_and_refresh).to eql(
          {
            user_token: 'accessT0ken',
            user_refresh_token: 'refreshT0ken'
          }
        )
      end
    end

    it 'fails due to unknown client' do
      VCR.use_cassette('get_token_from_code_unknown_client_error') do
        GgIpClientMate::Config.client_secret = 'wrongClientSecret'
        token_and_refresh = Oauth::OpenIdConnectClient.new.get_token_from_code('validCode')
        expect(token_and_refresh).to eql(nil)
      end
    end

    it 'fails due to invalid code' do
      VCR.use_cassette('get_token_from_code_invalid_code') do
        token_and_refresh = Oauth::OpenIdConnectClient.new.get_token_from_code('invalidCode')
        expect(token_and_refresh).to eql(nil)
      end
    end
  end

  describe '#revoke' do
    let(:user) { Struct.new(:oauth_token).new(oauth_token: 'activeToken') }

    it 'revokes an OAuth token for a given user' do
      VCR.use_cassette('revoke_token') do
        expect(Oauth::OpenIdConnectClient.new.revoke(user).code).to eql(200)
      end
    end
  end
end
