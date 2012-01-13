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
end
