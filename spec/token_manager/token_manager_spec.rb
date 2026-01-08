# frozen_string_literal: true

require 'spec_helper'

describe OpenFga::TokenManager::StaticTokenManager do
  it 'can be initialized with an api token' do
    tm = OpenFga::TokenManager::StaticTokenManager.new('api_token')
    expect(tm.access_token).to eq 'api_token'
  end
end

describe OpenFga::TokenManager::Oauth2TokenManager do
  let(:client_id) { 'client_id' }
  let(:client_secret) { 'client_secret' }
  let(:token_issuer) { 'token_issuer' }
  let(:audience) { 'audience' }

  describe described_class::Config do
    describe 'validation' do
      describe 'client_id' do
        it "can't be nil" do
          expect { described_class.new(client_id: nil, client_secret:, token_issuer:) }
            .to raise_error(ConfigurationError, /missing client_id/)
        end

        it "can't be empty" do
          expect { described_class.new(client_id: '', client_secret:, token_issuer:) }
            .to raise_error(ConfigurationError, /missing client_id/)
        end
      end

      describe 'client_secret' do
        it "can't be nil" do
          expect { described_class.new(client_id:, client_secret: nil, token_issuer:) }
            .to raise_error(ConfigurationError, /missing client_secret/)
        end

        it "can't be empty" do
          expect { described_class.new(client_id:, client_secret: '', token_issuer:) }
            .to raise_error(ConfigurationError, /missing client_secret/)
        end
      end

      describe 'token_issuer' do
        it "can't be nil" do
          expect { described_class.new(client_id:, client_secret:, token_issuer: nil) }
            .to raise_error(ConfigurationError, /missing token_issuer/)
        end

        it "can't be empty" do
          expect { described_class.new(client_id:, client_secret:, token_issuer: '') }
            .to raise_error(ConfigurationError, /missing token_issuer/)
        end
      end
    end

    it 'can create an instance and expose variables (with optional audience)' do
      subject = described_class.new(client_id:, client_secret:, token_issuer:, audience:)

      expect(subject.client_id).to eq client_id
      expect(subject.client_secret).to eq client_secret
      expect(subject.token_issuer).to eq token_issuer
      expect(subject.audience).to eq audience
    end
  end

  let(:config) { described_class::Config.new(client_id:, client_secret:, token_issuer:) }
  let(:subject) { described_class.new(config) }

  it 'provides access to the config' do
    expect(subject.config).to eq config
  end

  it 'refreshes and provides the access token' do
    stub = stub_request(:post, "https://#{token_issuer}/oauth/token")
             .with(
               body: {
                 "client_id": client_id,
                 "client_secret": client_secret,
                 "grant_type": 'client_credentials'
               }
             ).and_return(status: 200,
                          body: {
                            'access_token' => 'access_token',
                            'expires_in' => 3600
                          }.to_json)

    access_token = subject.access_token
    expect(stub).to have_been_requested
    expect(access_token).to eq 'access_token'
  end

  context 'when config has an audience set' do
    let(:config) { described_class::Config.new(client_id:, client_secret:, token_issuer:, audience:) }

    it 'refreshes and provides the access token (with audience)' do
      stub = stub_request(:post, "https://#{token_issuer}/oauth/token")
               .with(
                 body: {
                   "client_id": client_id,
                   "client_secret": client_secret,
                   "grant_type": 'client_credentials',
                   "audience": audience
                 }
               ).and_return(status: 200,
                            body: {
                              'access_token': 'access_token',
                              'expires_in': 3600
                            }.to_json)

      access_token = subject.access_token
      expect(stub).to have_been_requested
      expect(access_token).to eq 'access_token'
    end
  end

  context 'when the token cannot be refreshed' do
    it 'returns a TokenRefreshError' do
      stub = stub_request(:post, "https://#{token_issuer}/oauth/token")
                .with(
                  body: {
                    "client_id": client_id,
                    "client_secret": client_secret,
                    "grant_type": 'client_credentials',
                  }
                ).and_return(status: 401, body: 'invalid credentials')

      expect { subject.access_token }.to raise_error OpenFga::TokenManager::TokenRefreshError do |err|
        expect(err.message).to match(/invalid credentials/)
      end

      expect(stub).to have_been_requested
    end
  end
end
