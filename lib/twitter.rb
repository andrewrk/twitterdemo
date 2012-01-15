module Twitter
    require 'cgi'
    def Twitter.escape(str)
        CGI.escape(str.to_s).gsub('+', '%20')
    end

    # returns the OAuth value for the authorization http header
    require 'base64'
    require 'hmac-sha1'
    def Twitter.oAuth(o={})
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
        param_then_value = Proc.new do |a, b|
            first_order = a[0] <=> b[0]
            (first_order == 0) ? a[1] <=> b[1] : first_order
        end
        signature_params.sort! &param_then_value
        parameter_string = signature_params.collect{ |param, value|
            param + '=' + value
        }.join('&')
        signature_base_string = o[:method].upcase + '&' + escape(o[:base_url]) +
            '&' + escape(parameter_string)
        signing_key = escape(twitter_consumer_secret) + '&' +
            escape(o[:token_secret])

        oauth_hash['oauth_signature'] = (HMAC::SHA1.new(signing_key) <<
            signature_base_string).base64digest

        # percent encode every key and value
        oauth_params = oauth_hash.map { |k,v| [escape(k), escape(v)] }
        # sort by encoded key then encoded value
        oauth_params.sort! &param_then_value
        # serialize
        "OAuth " + oauth_params.collect{ |k,v|
            k + '="' + v + '"'
        }.join(', ')
    end

    # calls an external oauth url and returns the response, parsed into a hash
    require 'uri'
    require 'net/http'
    require 'rack'
    def Twitter.makeOAuthRequest(o={})
        o.reverse_merge! \
            :method => 'POST', # or GET
            :base_url => nil, # starting with https:// and not including any params
            :post_params => {},
            :get_params => {},
            :oauth_params => {},
            :token => '', # access token, sometimes we don't have it
            :token_secret => '', # access token secret, sometimes we don't have it
            :return_format => :query # other options :json, :plain

        fail if not o[:base_url].starts_with? 'https://'
        fail if o[:post_params] != {} and o[:method] != 'POST'

        url = URI.parse(o[:base_url])

        # add get params
        query = url.path
        if o[:get_params] != {}
            query += '?' + o[:get_params].collect{ |param, value|
                escape(param) + '=' + escape(value)
            }.join('&')
        end

        oauth = oAuth( \
            :method => o[:method],
            :params => o[:post_params].merge(o[:get_params]),
            :oauth_params => o[:oauth_params],
            :base_url => o[:base_url],
            :token => o[:token],
            :token_secret => o[:token_secret])
        auth_header_name = 'Authorization'
        if o[:method] == 'POST'
            request = Net::HTTP::Post.new(query)
            request[auth_header_name] = oauth
            request.set_form_data o[:post_params]
        else # GET
            request = Net::HTTP::Get.new(query)
            request.add_field(auth_header_name, oauth)
        end
        connection = Net::HTTP.new(url.host, url.port)
        connection.use_ssl = true
        response = connection.start do |http| 
            http.request request
        end

        if o[:return_format] == :query
            return Rack::Utils.parse_nested_query(response.body)
        elsif o[:return_format] == :json
            return ActiveSupport::JSON.decode(response.body)
        else # plain
            return response.body
        end
    end
end
