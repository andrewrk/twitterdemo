# because we need our url escaping to use '%20', not '+'
require 'cgi'
def escape(str)
    CGI.escape(str).gsub('+', '%20')
end

# returns the OAuth value for the authorization http header
require 'base64'
require 'hmac-sha1'
def oAuth(o={})
    o.reverse_merge! \
        :method => nil, # either 'GET' or 'POST'
        :base_url => nil, # starting with https:// and not including any params
        :oauth_params => {},
        :params => {},
        :token => '', # access token, sometimes we don't have it
        :token_secret => '' # access token secret, sometimes we don't have it

    fail if o[:method] == nil
    # base_url should not be escaped and should not contain any GET params.
    fail if not o[:base_url].starts_with? 'https://'

    twitter_consumer_key = ENV['TWITTER_CONSUMER_KEY']
    twitter_consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
    fail if twitter_consumer_key == nil
    fail if twitter_consumer_secret == nil

    oauth_hash = {
        'oauth_consumer_key' => twitter_consumer_key,
        'oauth_nonce' => Base64.strict_encode64((1..32).collect {
            rand(256).chr }.join),
        'oauth_signature_method' => 'HMAC-SHA1',
        'oauth_timestamp' => Time.now.to_i.to_s,
        'oauth_version' => '1.0',
    }
    if not o[:token].blank?
        oauth_hash['oauth_token'] = o[:token]
    end
    oauth_hash.merge! o[:oauth_params]

    # generate oauth_signature
    # percent encode every key and value
    signature_params = o[:params].merge(oauth_hash).map{ |param, value|
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
    signature_base_string = o[:method].upcase + '&' + escape(o[:base_url]) +
        '&' + escape(parameter_string)
    signing_key = escape(twitter_consumer_secret) + '&' +
        escape(o[:token_secret])

    oauth_hash['oauth_signature'] = (HMAC::SHA1.new(signing_key) <<
        signature_base_string).base64digest

    "OAuth " + oauth_hash.collect{ |param, value|
        escape(param) + '="' + escape(value) + '"'
    }.join(', ')
end

# calls an external oauth url and returns the response, parsed into a hash
require 'uri'
require 'net/http'
require 'rack'
def makeOAuthPost(o={})
    o.reverse_merge! \
        :base_url => nil, # starting with https:// and not including any params
        :post_params => {},
        :oauth_params => {},
        :token => '', # access token, sometimes we don't have it
        :token_secret => '' # access token secret, sometimes we don't have it

    fail if not o[:base_url].starts_with? 'https://'

    url = URI.parse(o[:base_url])
    oauth = oAuth(:method => "POST",
        :params => o[:post_params],
        :oauth_params => o[:oauth_params],
        :base_url => o[:base_url],
        :token => o[:token],
        :token_secret => o[:token_secret])
    request = Net::HTTP::Post.new(url.path)
    request['Authorization'] =  oauth
    request.set_form_data o[:post_params]
    connection = Net::HTTP.new(url.host, url.port)
    connection.use_ssl = true
    response = connection.start do |http| 
        http.request request
    end

    Rack::Utils.parse_nested_query(response.body)
end

class MainController < ApplicationController
    def home
        @screen_name = cookies[:screen_name]
    end

    def search
        render 'home'
    end

    def signin
        response = makeOAuthPost \
            :base_url => 'https://api.twitter.com/oauth/request_token',
            :oauth_params => {'oauth_callback' => signin_done_url}

        # get request token from twitter
        fail if response['oauth_callback_confirmed'] != 'true'

        # save as cookies in user's browser
        token = response['oauth_token']
        cookies.permanent[:oauth_token] = token
        cookies.permanent[:oauth_token_secret] = response['oauth_token_secret']
        
        redirect_to 'https://api.twitter.com/oauth/authorize?oauth_token='+token
    end

    def signin_done
        # convert token to access token
        token = cookies[:oauth_token]
        token_secret = cookies[:oauth_token_secret]

        puts "cookie token: " + token
        puts "param token: " + params[:oauth_token]
        fail if token != params[:oauth_token]

        response = makeOAuthPost \
            :base_url => 'https://api.twitter.com/oauth/access_token',
            :post_params => {'oauth_verifier' => params[:oauth_verifier]},
            :token => token,
            :token_secret => token_secret
        
        # save user information to cookie
        cookies.permanent[:oauth_token] = response['oauth_token']
        cookies.permanent[:oauth_token_secret] = response['oauth_token_secret']
        cookies.permanent[:user_id] = response['user_id']
        cookies.permanent[:screen_name] = response['screen_name']
        
        redirect_to '/'
    end
end
