#= require page

class HomePage extends RTD.Page
    _requestCurrentPage: ->
        start = @current_page * @results_per_page
        end = start + @results_per_page
        friends = @friends.ids[start...end]
        # fetch our user while we're at it
        friends.push(@user_id)

        $.ajax
            type: 'POST'
            url: '/api'
            data:
                method: 'GET'
                path: '/users/lookup.json'
                get_params: JSON.stringify
                    user_id: friends.join(',')
                    include_entities: false
            success: (data) =>
                # merge the results into our cache
                for user in data
                    @users[user.id] = user

                @render()

    _requestFriends: ->
        $.ajax
            type: 'POST'
            url: '/api'
            data:
                method: 'GET'
                path: '/friends/ids.json'
                get_params: JSON.stringify
                    user_id: @user_id
                    cursor: -1
            success: (data) =>
                @friends = data
                @_requestCurrentPage()

    constructor: (params) ->
        super(params)

        @current_page = parseInt(params.page) || 0
        @results_per_page = 20
        @friends = null
        # users we want to unfollow (id => true/not true)
        @unfollow_users = {}
        # list of success/failure for following/unfollowing
        @completed_actions = null

        if @signed_in
            @_requestFriends()

    canonicalUrl: ->
        if @completed_actions?
            return "/#/results"
        else
            "/#/?page=" + @current_page

    _markAsNewPage: ->
        history?.pushState {}, '', @canonicalUrl()

    render: ->
        super()

        # prepare data
        if @completed_actions?
            context =
                completed_actions: @completed_actions
                label: "Unfollow results"
        else
            if @friends?
                start = @current_page * @results_per_page
                end = start + @results_per_page
                context =
                    completed_actions: null
                    results: (@users[id] for id in @friends.ids[start...end])
                    has_prev: start > 0
                    has_next: end < @friends.ids.length
                    action_checked: @unfollow_users
                    action_label: "Unfollow"
                    label: "Followees"
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
            @_requestCurrentPage()
            @_markAsNewPage()
            return false

        content.find(".nav-prev").on 'click', (event) =>
            @current_page -= 1
            @_requestCurrentPage()
            @_markAsNewPage()
            return false

        content.find(".action").on 'change', (event) =>
            checkbox = $(event.target)
            id = checkbox.data('id')
            is_checked = checkbox.is(':checked')
            @unfollow_users[id] = is_checked
            return false
        
        content.find(".submit").on 'click', (event) =>
            # unfollow every checked user one by one
            @completed_actions = {}
            @_markAsNewPage()
            @render()
            for own user_id, unfollow of @unfollow_users
                if unfollow
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
                                path: '/friendships/destroy.json'
                                post_params: JSON.stringify
                                    user_id: user_id
                                    include_entities: false
                            success: (data) =>
                                if data.error?
                                    done 'error'
                                else
                                    done 'success'
                            error: => done 'error'
            @render()

            @unfollow_users = {}
            return false

RTD.HomePage = HomePage
