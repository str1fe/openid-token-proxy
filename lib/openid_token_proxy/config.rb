require 'openid_connect'

module OpenIDTokenProxy
  class Config
    attr_accessor :client_id, :client_secret, :issuer
    attr_accessor :domain_hint, :prompt, :redirect_uri, :resource
    attr_accessor :authorization_uri
    attr_accessor :authorization_endpoint, :token_endpoint, :userinfo_endpoint
    attr_accessor :token_acquirement_hook
    attr_accessor :public_keys

    def initialize
      @client_id = ENV['OPENID_CLIENT_ID']
      @client_secret = ENV['OPENID_CLIENT_SECRET']
      @issuer = ENV['OPENID_ISSUER']

      @domain_hint = ENV['OPENID_DOMAIN_HINT']
      @prompt = ENV['OPENID_PROMPT']
      @redirect_uri = ENV['OPENID_REDIRECT_URI']
      @resource = ENV['OPENID_RESOURCE']

      @authorization_uri = ENV['OPENID_AUTHORIZATION_URI']

      @authorization_endpoint = ENV['OPENID_AUTHORIZATION_ENDPOINT']
      @token_endpoint = ENV['OPENID_TOKEN_ENDPOINT']
      @userinfo_endpoint = ENV['OPENID_USERINFO_ENDPOINT']

      @token_acquirement_hook = proc { }

      yield self if block_given?
    end

    def provider_config
      # TODO: Add support for refreshing provider configuration
      @provider_config ||= begin
        OpenIDConnect::Discovery::Provider::Config.discover! issuer
      end
    end

    def authorization_endpoint
      @authorization_endpoint || provider_config.authorization_endpoint
    end

    def token_endpoint
      @token_endpoint || provider_config.token_endpoint
    end

    def userinfo_endpoint
      @userinfo_endpoint || provider_config.userinfo_endpoint
    end

    def public_keys
      @public_keys ||= provider_config.public_keys
    end
  end
end
