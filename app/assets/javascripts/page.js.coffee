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

    markAsNewPage: ->
        history?.pushState {}, '', @canonicalUrl()


class ResultsAndActionPage extends Page
    constructor: (params) ->
        super(params)

        @results_per_page = 20
        @current_page = parseInt(params.page) || 0
        @results = null
        # users we want to perform the action on
        @action_users = {}
        # list of success/failure for following/unfollowing
        @completed_actions = null

    render: ->
        super()

        # prepare data
        if @completed_actions?
            context =
                completed_actions: @completed_actions
                label: @completed_action_label
        else
            if @results?
                context = @getCurrentPageContext()
            else
                context =
                    completed_actions: null
                    results: null
                    signed_in: @signed_in

        # render templates
        content = $("#content")
        content.html(Jst.evaluate(RTD.layouts.results, context))
        
        # add hooks
        content.find(".nav-next").on 'click', (event) =>
            @current_page += 1
            @requestCurrentPage()
            @markAsNewPage()
            return false

        content.find(".nav-prev").on 'click', (event) =>
            @current_page -= 1
            @requestCurrentPage()
            @markAsNewPage()
            return false

        content.find(".action").on 'change', (event) =>
            checkbox = $(event.target)
            id = checkbox.data('id')
            is_checked = checkbox.is(':checked')
            @action_users[id] = is_checked
            return false
        
        content.find(".submit").on 'click', (event) =>
            # take action on every checked user one by one
            @completed_actions = {}
            @markAsNewPage()
            @render()
            for own user_id, take_action of @action_users
                if take_action
                    @completed_actions[user_id] =
                        success: 'notice'
                        screen_name: @users[user_id].screen_name
                        name: @users[user_id].name
                    do (user_id) =>
                        done = (success) =>
                            @completed_actions[user_id].success = success
                            @render()
                        $.ajax
                            type: 'POST'
                            url: '/api'
                            data:
                                method: 'POST'
                                path: @api_path
                                post_params: JSON.stringify
                                    user_id: user_id
                            success: (data) =>
                                if data.error?
                                    done 'error'
                                else
                                    done 'success'
                            error: => done 'error'
            @render()

            @action_users = {}
            return false

        content.find('a[href="#/"]').on 'click', (event) =>
            RTD.navToAddress '/'
            return false


# exports
RTD.Page = Page
RTD.ResultsAndActionPage = ResultsAndActionPage
