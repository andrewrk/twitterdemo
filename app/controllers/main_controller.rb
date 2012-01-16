# because we need our url escaping to use '%20', not '+'
class MainController < ApplicationController
  require 'twitter'

  def home
  end

  def signin
    # get request token from twitter
    response = Twitter.makeOAuthRequest \
      :base_url => 'https://api.twitter.com/oauth/request_token',
      :oauth_params => {'oauth_callback' => signin_done_url}

    if response.blank? or response['oauth_callback_confirmed'] != 'true'
      render 'signin_err'
      return
    end

    # save as cookies in user's browser
    token = response['oauth_token']
    cookies.permanent[:oauth_token] = token
    cookies.permanent[:oauth_token_secret] = response['oauth_token_secret']
    
    redirect_to "https://api.twitter.com/oauth/authorize?oauth_token=#{token}"
  end

  def signin_done
    # convert token to access token
    token = cookies[:oauth_token]
    token_secret = cookies[:oauth_token_secret]

    if token != params[:oauth_token] or token.blank? or token_secret.blank?
      render 'signin_err'
      return
    end

    response = Twitter.makeOAuthRequest \
      :base_url => 'https://api.twitter.com/oauth/access_token',
      :post_params => {'oauth_verifier' => params[:oauth_verifier]},
      :token => token,
      :token_secret => token_secret

    render 'signin_err' and return if response.blank?
    
    # save user information to cookie
    cookies.permanent[:oauth_token] = response['oauth_token']
    cookies.permanent[:oauth_token_secret] = response['oauth_token_secret']
    cookies.permanent[:user_id] = response['user_id']
    cookies.permanent[:screen_name] = response['screen_name']
    
    redirect_to root_path
  end

  # proxy to twitter API
  def api
    token = cookies[:oauth_token]
    token_secret = cookies[:oauth_token_secret]

    if token.blank? or token_secret.blank?
      render :json => {:error => "not authenticated"}
      return
    end

    get_params = params[:get_params] || '{}'
    post_params = params[:post_params] || '{}'

    response = Twitter.makeOAuthRequest \
      :method => params[:method],
      :base_url => "https://api.twitter.com/1#{params[:path]}",
      :get_params => ActiveSupport::JSON.decode(get_params),
      :post_params => ActiveSupport::JSON.decode(post_params),
      :token => token,
      :token_secret => token_secret,
      :return_format => :json
    
    render :json => response
  end
end
