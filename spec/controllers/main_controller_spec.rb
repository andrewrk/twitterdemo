require 'spec_helper'

describe MainController do
    describe "GET 'home'" do
        it "should be successful" do
            get 'home'
            response.should be_success
        end
    end

    describe "GET 'search'" do
        it "should be successful" do
            get 'search'
            response.should be_success
        end
    end

    describe "GET 'signin'" do
        it "should redirect to twitter" do
            get 'signin'
            response.code.should == '302'
            (response.redirect_url.start_with? 'https://api.twitter.com/oauth/authorize').should equal true
        end
    end

    describe "GET 'signin/done'" do
        it "should display an error message upon error" do
            get 'signin_done'
            response.should render_template('signin_err')
        end
    end

    describe "GET 'ajax/followers'" do
        it "should be successful" do
            get 'ajax_followers'
            response.should be_success
        end
        it "should return a list of 20 followers" do
            get 'ajax_followers'
            followers = ActiveSupport::JSON.decode(response.body)
            followers.length.should equal 20
        end
    end
end
