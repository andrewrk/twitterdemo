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
        it "should redirect to twitter"
    end

    describe "GET 'signin/done'" do
        it "should save a cookie upon success"
        it "should redirect to home page upon success"
        it "should display an error message upon error"
    end
end
