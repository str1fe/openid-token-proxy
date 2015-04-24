require 'openid_token_proxy/token/expired'
require 'openid_token_proxy/token/invalid_application'
require 'openid_token_proxy/token/invalid_audience'
require 'openid_token_proxy/token/invalid_issuer'
require 'openid_token_proxy/token/malformed'
require 'openid_token_proxy/token/required'
require 'openid_token_proxy/token/unverifiable_signature'

module OpenIDTokenProxy
  class Token
    attr_accessor :access_token, :id_token, :refresh_token

    def initialize(access_token, id_token = nil, refresh_token = nil)
      @access_token = access_token
      @id_token = id_token
      @refresh_token = refresh_token
    end

    def to_s
      @access_token
    end

    # Validates this token's expiration state, application, audience and issuer
    def validate!(assertions = {})
      raise Expired if expired?

      # TODO: Nonce validation

      if assertions[:audience]
        audiences = Array(id_token.aud)
        raise InvalidAudience unless audiences.include? assertions[:audience]
      end

      if assertions[:client_id]
        appid = id_token.raw_attributes['appid']
        raise InvalidApplication if appid && appid != assertions[:client_id]
      end

      if assertions[:issuer]
        issuer = id_token.iss
        raise InvalidIssuer unless issuer == assertions[:issuer]
      end

      true
    end

    def expired?
      id_token.exp.to_i <= Time.now.to_i
    end

    # Decodes given access token and validates its signature by public key(s)
    # Use :skip_verification as second argument to skip signature validation
    def self.decode!(access_token, keys = OpenIDTokenProxy.config.public_keys)
      raise Required if access_token.blank?

      Array(keys).each do |key|
        begin
          object = OpenIDConnect::RequestObject.decode(access_token, key)
        rescue JSON::JWT::InvalidFormat => e
          raise Malformed.new(e.message)
        rescue JSON::JWT::VerificationFailed
          # Iterate through remaining public keys (if any)
          # Raises TokenInvalid if none applied (see below)
        else
          id_token = OpenIDConnect::ResponseObject::IdToken.new(object.raw_attributes)
          token = Token.new(access_token)
          token.id_token = id_token
          return token
        end
      end

      raise UnverifiableSignature
    end
  end
end
