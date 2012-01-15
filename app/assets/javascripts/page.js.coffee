#= require jquery.cookie
#= require layouts

base_title = document.title
class Page
    _cacheSignInState: ->
        @user_id = $.cookie('user_id')
        @screen_name = $.cookie('screen_name')
        @signed_in = @user_id? and @screen_name?

        if @users[@user_id]?
            @avatar = @users[@user_id].profile_image_url

    constructor: (params) ->
        @signed_in = false
        @user_id = null
        @screen_name = null
        @avatar = null
        @users = {} # cache of user data, indexed by id
        @base_title = base_title
        @query = '' # search query

        @_cacheSignInState()

    render: ->
        # prepare data
        @_cacheSignInState()

        # render templates
        nav = $("#nav")
        nav.html(Jst.evaluate(RTD.layouts.nav, this))

        # add hooks
        nav.find(".signout").on 'click', (event) =>
            # delete cookies
            $.cookie('user_id', null)
            $.cookie('screen_name', null)

            # set url to home page
            RTD.navToAddress '/'
            return false
        
        nav.find(".search").on 'keydown', (event) =>
            if event.keyCode == 13
                # navigate to search page
                query = escape($(event.target).val())
                RTD.navToAddress "search?q=#{query}"
                return false
            return true

RTD.Page = Page
