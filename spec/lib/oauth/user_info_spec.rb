RSpec.describe Oauth::UserInfo do
  before do
    GgIpClientMate::Config.client_identifier = 'customClientIdentifier'
    GgIpClientMate::Config.client_secret = 'customClientSecret'
    GgIpClientMate::Config.oauth_provider_uri = 'https://test-identiy-provider.com'
    GgIpClientMate::Config.redirect_uri = 'http://test-client.com/oauth_login'
    GgIpClientMate::Config.root_uri = 'http://test-client.com'
  end

  describe '#info' do
    it 'returns user info if valid token' do
      VCR.use_cassette('user_info') do
        user_info = Oauth::UserInfo.info('8aCGrR1MBAWOPNdqjFdlhEagVsIuOpHMdDxrIWh7hXg')
        expect(user_info).to eql(
          {
            'sub' => '1',
            'email' => 'admin@ggidentity.com',
            'first_name' => 'GolfGenius',
            'last_name' => 'Identity Admin12',
            'phone' => '078888888',
            'phone_prefix' => '+61',
            'phone_prefix_country' => 'AU',
            'gender' => 'F',
            'ghin_number' => '888888'
          }
        )
      end
    end

    it 'returns nil if invalid token' do
      VCR.use_cassette('user_info_invalid_token') do
        user_info = Oauth::UserInfo.info('invalidToken')
        expect(user_info).to eql(nil)
      end
    end
  end

  describe '#get_new_token_and_refresh' do
    let(:user) { Struct.new(:oauth_token, :oauth_refresh_token).new(oauth_token: 'expiredToken', oauth_refresh_token: 'refreshToken') }

    it 'obtains a new access token and refresh token pair from IP using the user\'s existing refresh token' do
      GgIpClientMate::Config.oauth_token_attribute_name = 'oauth_token'
      GgIpClientMate::Config.oauth_refresh_token_attribute_name = 'oauth_refresh_token'

      VCR.use_cassette('get_new_token_and_refresh') do
        token_and_refresh = Oauth::UserInfo.get_new_token_and_refresh(user)
        expect(token_and_refresh).to eql(
          {
            user_token: 'newToken',
            user_refresh_token: 'newRefresh'
          }
        )
      end
    end

    it 'raises error when refresh token is invalid' do
      GgIpClientMate::Config.oauth_token_attribute_name = 'oauth_token'
      GgIpClientMate::Config.oauth_refresh_token_attribute_name = 'oauth_refresh_token'

      VCR.use_cassette('get_new_token_and_refresh_invalid') do
        expect { Oauth::UserInfo.get_new_token_and_refresh(user) }.to raise_error(GgIpClientMate::InvalidAuthorizationGrantError)
      end
    end
  end

  describe '#user_attributes' do
    before do
      GgIpClientMate::Config.oauth_token_attribute_name = :oauth_token
      GgIpClientMate::Config.oauth_refresh_token_attribute_name = :oauth_refresh_token
      GgIpClientMate::Config.user_info_attribute_mapping = {
        ip_external_id: 'sub',
        email: 'email',
        firstname: 'first_name',
        ghin_no: 'ghin_number'
      }
    end

    it 'returns a has of user attributes mapped over doorkeeper values' do
      attributes = Oauth::UserInfo.user_attributes(
        {
          'sub' => '8888',
          'email' => 'ben.dover@golfgenius.com',
          'first_name' => 'Ben',
          'ghin_number' => '88888888'
        },
        {
          user_token: 'customToken',
          user_refresh_token: 'refreshToken'
        }
      )

      expect(attributes).to eql(
        {
          ip_external_id: '8888',
          email: 'ben.dover@golfgenius.com',
          firstname: 'Ben',
          ghin_no: '88888888',
          oauth_refresh_token: 'refreshToken',
          oauth_token: 'customToken'
        }
      )
    end
  end

  describe '#assign_user_attributes_and_save' do
    let(:fake_user) do
      Struct.new(:oauth_token, :oauth_refresh_token, :email, :firstname, :saved) do
        def assign_attributes_and_association_attributes(detail)
          self.email = detail[:email]
          self.firstname = detail[:firstname]
        end

        def save_with_associations
          self.saved = true
        end
      end
    end

    before :each do
      GgIpClientMate::Config.oauth_token_attribute_name = :oauth_token
      GgIpClientMate::Config.oauth_refresh_token_attribute_name = :oauth_refresh_token
      GgIpClientMate::Config.user_info_attribute_mapping = {
        email: 'email',
        firstname: 'first_name'
      }

      @user = fake_user.new
    end

    it 'updates an existing user record with the latest info from IP' do
      Oauth::UserInfo.assign_user_attributes_and_save(
        @user,
        { user_token: 'customToken', user_refresh_token: 'refreshToken' },
        {
          'email' => 'ben.dover@golfgenius.com',
          'first_name' => 'Ben'
        }
      )

      expect(@user.saved).to be_truthy
      expect(@user.email).to eql 'ben.dover@golfgenius.com'
      expect(@user.firstname).to eql 'Ben'
    end
  end

  describe '#user_create_or_update_with_associations' do
    let(:fancy_user) do
      Struct.new(:oauth_token, :oauth_refresh_token, :email, :firstname, :saved) do
        def assign_attributes_and_association_attributes(details); end

        def save_with_associations
          self.saved = true
        end

        def reload
          self
        end
      end
    end

    before do
      stub_const 'User', fancy_user
      GgIpClientMate::Config.user_info_attribute_mapping = {}
    end

    it 'returns nil when blank user info' do
      expect(Oauth::UserInfo.user_create_or_update_with_associations(nil, nil, nil)).to eql nil
    end

    it 'assigns latest data to existing user' do
      user = fancy_user.new

      Oauth::UserInfo.user_create_or_update_with_associations(user, {}, { email: 'ben.dover@golfgenius.com' })
      expect(user.saved).to eql(true)
    end

    it 'creates new user and assigns latest data' do
      user = Oauth::UserInfo.user_create_or_update_with_associations(nil, {}, { email: 'ben.dover@golfgenius.com' })
      expect(user.saved).to eql(true)
    end
  end

  describe '#update_source' do
    let(:slim_user) do
      Struct.new(:oauth_token, :first_name) do
        def user_info
          {
            first_name: first_name
          }
        end
      end
    end

    before :each do
      GgIpClientMate::Config.oauth_token_attribute_name = :oauth_token
      GgIpClientMate::Config.oauth_refresh_token_attribute_name = :oauth_refresh_token
      GgIpClientMate::Config.user_info_attribute_mapping = { first_name: 'first_name' }
      @user = slim_user.new(oauth_token: 'oauthToken', first_name: 'Dover')
    end

    it 'updates the user account settings in the IP app' do
      VCR.use_cassette('update_source') do
        expect(Oauth::UserInfo.update_source(@user, avatar_changed: true)).to be_truthy
      end
    end

    it "doesn't update IP user when invalid token" do
      VCR.use_cassette('update_source_invalid_token') do
        expect { Oauth::UserInfo.update_source(@user) }.to raise_error(GgIpClientMate::InvalidAuthorizationGrantError)
      end
    end
  end

  describe '#update_password' do
    before do
      GgIpClientMate::Config.oauth_token_attribute_name = :oauth_token

      @user = Struct.new(:oauth_token).new(oauth_token: 'irwLm3c9iAqoVkPt_YkG0bQtMp97BImFq8IwNTwd1fk')
    end

    it 'updates the user password' do
      VCR.use_cassette('update_password') do
        password_updated_response = Oauth::UserInfo.update_password(@user, 'password123', 'password123', 'validPassword')
        expect(password_updated_response).to eql(
          {
            code: 200,
            error_message: ''
          }
        )
      end
    end

    it "doesn't update IP user password when invalid old password" do
      VCR.use_cassette('update_password_invalid_old_password') do
        password_updated_response = Oauth::UserInfo.update_password(@user, 'password123', 'password123', 'wrongPassword')
        expect(password_updated_response).to eql(
          {
            code: 422,
            error_message: 'Wrong password'
          }
        )
      end
    end

    it "doesn't update IP user password when invalid new password" do
      VCR.use_cassette('update_password_invalid_new_password') do
        password_updated_response = Oauth::UserInfo.update_password(@user, 'password123', 'password123', 'validPassword')
        expect(password_updated_response).to eql(
          {
            code: 422,
            error_message: 'Password is too short (minimum is 8 characters) and Password should include lower case characters and numbers'
          }
        )
      end
    end
  end

  describe '#create_associated_user' do
    let(:slim_user) do
      Struct.new(:oauth_token, :first_name, :saved) do
        def user_info
          {
            first_name: first_name
          }
        end

        def assign_attributes_and_association_attributes(details); end

        def save_with_associations
          self.saved = true
        end

        def reload
          self
        end
      end
    end

    before :each do
      GgIpClientMate::Config.oauth_token_attribute_name = :oauth_token
      GgIpClientMate::Config.oauth_refresh_token_attribute_name = :oauth_refresh_token
      GgIpClientMate::Config.user_info_attribute_mapping = { firstname: 'first_name' }
      @user = slim_user.new(oauth_token: 'secret_token', first_name: 'Dover')
      stub_const 'User', slim_user
      @new_user_params = { first_name: 'Ben', last_name: 'Dover', phone: '1234567890', phone_prefix: '+40', phone_prefix_country: 'RO', gender: 'F', username: 'bendover', password: 'password123' }
    end

    it 'creates new user with valid attributes' do
      VCR.use_cassette('create_associated_user') do
        user = Oauth::UserInfo.create_associated_user(@user, @new_user_params)

        expect(user.saved).to eql(true)
      end
    end

    it 'account with specific username exists' do
      VCR.use_cassette('create_associated_user_fail_due_to_existing_username') do
        expect do
          Oauth::UserInfo.create_associated_user(@user, @new_user_params)
        end.to raise_error(GgIpClientMate::InvalidRequestError)
      end
    end

    it 'invalid passowrd' do
      VCR.use_cassette('create_associated_user_fail_due_to_invalid_password') do
        expect do
          Oauth::UserInfo.create_associated_user(@user, { first_name: 'Ben', last_name: 'Dover', phone: '1234567890', phone_prefix: '+40', phone_prefix_country: 'RO', gender: 'F', username: 'bendover', password: '' })
        end.to raise_error(GgIpClientMate::InvalidRequestError, "Password can't be blank; Password should include lower case characters, numbers and has minimum 8 characters")
      end
    end

    it 'feature disabled' do
      VCR.use_cassette('create_associated_user_fail_due_to_feature_disabled') do
        expect do
          Oauth::UserInfo.create_associated_user(@user, @new_user_params)
        end.to raise_error(GgIpClientMate::InvalidRequestError, 'Your application is not authorized to perform this action')
      end
    end
  end
end
