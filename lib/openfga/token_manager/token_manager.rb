# frozen_string_literal: true

module OpenFga
  module TokenManager
    # TokenRefreshError is raised if the access token cannot be refreshed from the authorization server. 
    class TokenRefreshError < StandardError
      def initialize(message)
        @message = message
        super "Token refresh error: #{message}"
      end
    end

    # NoopTokenManager just returns a nil token.
    # Looks redundant but makes usage code easier as we don't have to have special case code when we want an
    # access token if authorization is not configured.
    class NoopTokenManager
      attr_reader :access_token
      def initialize
        @access_token = nil
      end
    end

    # StaticTokenManager just keeps a hold of and returns whatever token is given to the client by the caller,
    # in case they're using their own access token.
    class StaticTokenManager
      attr_reader :access_token

      def initialize(access_token)
        @access_token = access_token
      end
    end

    # Oauth2TokenManager uses the /oauth/token endpoint on a token issuer to fetch a new token using the
    # Oauth2 standard.
    class Oauth2TokenManager
      class Config
        attr_reader :client_id, :client_secret, :token_issuer, :audience, :logger

        def initialize(client_id:, client_secret:, token_issuer:, audience: nil, logger: nil)
          raise ConfigurationError, 'missing client_id' if client_id.blank?
          raise ConfigurationError, 'missing client_secret' if client_secret.blank?
          raise ConfigurationError, 'missing token_issuer' if token_issuer.blank?

          @client_id = client_id
          @client_secret = client_secret
          @token_issuer = token_issuer
          @audience = audience
          @logger = logger
        end
      end

      attr_reader :config

      def initialize(config)
        @config = config
        @access_token_expires_at = nil
        @access_token = nil
        @logger = config.logger || Logger.new(STDOUT)
      end

      def access_token
        if @access_token_expires_at && @access_token_expires_at > (Time.now.utc + 60)
          return @access_token
        end

        @logger.debug "Refreshing access token from #{@config.token_issuer}"

        form_data = {
          'grant_type' => 'client_credentials',
          'client_id' => @config.client_id,
          'client_secret' => @config.client_secret
        }

        if @config.audience
          form_data['audience'] = @config.audience
        end

        uri = URI.parse("https://#{@config.token_issuer}/oauth/token")
        request = Net::HTTP::Post.new(uri)
        request.set_form_data(form_data)
  
        req_options = {
          use_ssl: uri.scheme == 'https'
        }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end
          
        if response.code.to_i == 200
          body = JSON.parse(response.body)
          @access_token = body['access_token']
          @access_token_expires_at = Time.now.utc + body['expires_in'].to_i

          @logger.debug "Obtained new access token, expires at #{@access_token_expires_at}"

          @access_token
        else raise TokenRefreshError.new("Failed to obtain access token: #{response.code} #{response.body}")
        end
      end
    end
  end
end
