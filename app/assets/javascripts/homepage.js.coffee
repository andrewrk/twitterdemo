#= require page

class HomePage extends RTD.ResultsAndActionPage
    requestCurrentPage: ->
        start = @current_page * @results_per_page
        end = start + @results_per_page
        friends = @results.ids[start...end]
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
                @results = data
                @requestCurrentPage()

    constructor: (params) ->
        super(params)

        @completed_action_label = "Unfollow results"
        @api_path = '/friendships/destroy.json'

        if @signed_in
            @_requestFriends()

    canonicalUrl: ->
        if @completed_actions?
            return "/#/results"
        else
            return "/#/?page=" + @current_page

    getCurrentPageContext: ->
        start = @current_page * @results_per_page
        end = start + @results_per_page
        return {} =
            completed_actions: null
            results: (@users[id] for id in @results.ids[start...end])
            has_prev: start > 0
            has_next: end < @results.ids.length
            action_checked: @action_users
            action_label: "Unfollow"
            label: "Followees"


RTD.HomePage = HomePage
