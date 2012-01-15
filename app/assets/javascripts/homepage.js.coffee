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

        @current_page = 0
        @results_per_page = 20
        @friends = null
        @unfollow_users = {} # users we want to unfollow (id => true/not true)

        if @signed_in
            @_requestFriends()

    render: ->
        super()

        # prepare data
        if @friends?
            start = @current_page * @results_per_page
            end = start + @results_per_page
            context =
                results: (@users[id] for id in @friends.ids[start...end])
                has_prev: start > 0
                has_next: end < @friends.ids.length
                unfollow_users: @unfollow_users
        else
            context =
                results: null
                signed_in: @signed_in

        # render templates
        content = $("#content")
        content.html(Jst.evaluate(RTD.layouts.results, context))
        
        # add hooks
        content.find(".nav-next").on 'click', (event) =>
            @current_page += 1
            @_requestCurrentPage()
            return false

        content.find(".nav-prev").on 'click', (event) =>
            @current_page -= 1
            # don't need to request old pages, they're already cached
            @render()
            return false

        content.find(".unfollow").on 'change', (event) =>
            checkbox = $(event.target)
            id = checkbox.data('id')
            is_checked = checkbox.is(':checked')
            @unfollow_users[id] = is_checked
            return false
        
        content.find(".submit").on 'click', (event) =>
            # unfollow every checked user one by one
            $(event.target).hide()
            for own user_id, unfollow of @unfollow_users
                if unfollow
                    $.ajax
                        type: 'POST'
                        url: '/api'
                        data:
                            method: 'POST'
                            path: '/friendships/destroy.json'
                            post_params: JSON.stringify
                                user_id: user_id
                                include_entities: false

            @unfollow_users = {}

            setTimeout =>
                @current_page = 0
                @_requestCurrentPage()
            , 1000

            return false

RTD.HomePage = HomePage
