# because we need our url escaping to use '%20', not '+'
require 'cgi'
def escape(str)
    CGI.escape(str).gsub('+', '%20')
end

# returns the OAuth value for the authorization http header
require 'base64'
require 'hmac-sha1'
def oAuthRequest(method, base_url, params, token, token_secret)
    # base_url should not be escaped and should not contain any GET params.
    fail if not base_url.starts_with? 'https://'

    oauth_hash = {
        'oauth_consumer_key' => ENV['TWITTER_CONSUMER_KEY'],
        'oauth_nonce' => Base64.strict_encode64((1..32).collect {
            rand(256).chr }.join),
        'oauth_signature_method' => 'HMAC-SHA1',
        'oauth_timestamp' => Time.now.to_i.to_s,
        'oauth_version' => '1.0',
        'oauth_token' => token,
    }

    # generate oauth_signature
    # percent encode every key and value
    signature_params = (params + oauth_hash.to_a).map{ |param, value|
        [escape(param), escape(value)]
    }
    # sort alphabetically by encoded key, then encoded value
    signature_params.sort! do |a, b|
        first_order = a[0] <=> b[0]
        (first_order == 0) ? a[1] <=> b[1] : first_order
    end
    parameter_string = signature_params.collect{ |param, value|
        param + '=' + value
    }.join('&')
    signature_base_string = method.upcase + '&' + escape(base_url) + '&' +
        escape(parameter_string)
    consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
    signing_key = escape(consumer_secret) + '&' + escape(token_secret)

    oauth_hash['oauth_signature'] = (HMAC::SHA1.new(signing_key) <<
        signature_base_string).base64digest


    "OAuth " + oauth_hash.collect{ |param, value|
        escape(param) + '="' + escape(value) + '"'
    }.join(', ')
end


class MainController < ApplicationController
    def home
        
    end

    def search
        render 'home'
    end

    def signin
        # get request token from twitter
        
        # redirect user to authorize
    end

    def signin_done
        # set cookie
        
        # redirect to home
    end
end
