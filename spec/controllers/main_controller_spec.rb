require 'spec_helper'

describe MainController do
    describe "GET 'home'" do
        it "should be successful" do
            get 'home'
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
end
