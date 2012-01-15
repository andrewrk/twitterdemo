#= require page

class SearchPage extends RTD.Page
    _requestSearch: ->
        $.ajax
            type: 'POST'
            url: '/api'
            data:
                method: 'GET'
                path: '/users/search.json'
                get_params: JSON.stringify
                    q: @query
                    page: @current_page
                    per_page: @results_per_page
            success: (data) =>
                @results = data
                @render()

    constructor: (params) ->
        super(params)
        @base_title = "Search - " + @base_title
        @results_per_page = 20
        @current_page = 1
        @query = params.q
        @terms = @query.split(/\s+/)
        @results = null
        @follow_users = {} # users we want to follow

        @_requestSearch()

    render: ->
        super()

        # prepare data
        if @results?
            context =
                results: @results
                has_prev: @current_page > 1
                has_next: true
                action_checked: @follow_users
                action_label: "Follow"
                label: "Search Results"
        else
            context =
                results: null
                signed_in: @signed_in

        # render templates
        document.title = "#{@query} - #{@base_title}"
        content = $("#content")
        content.html(Jst.evaluate(RTD.layouts.results, context))

        # add hooks
        content.find(".nav-next").on 'click', (event) =>
            @current_page += 1
            @_requestSearch()
            return false

        content.find(".nav-prev").on 'click', (event) =>
            @current_page -= 1
            @_requestSearch()
            return false

        content.find(".action").on 'change', (event) =>
            checkbox = $(event.target)
            id = checkbox.data('id')
            is_checked = checkbox.is(':checked')
            @follow_users[id] = is_checked
            return false
        
        content.find(".submit").on 'click', (event) =>
            # follow every checked user one by one
            $(event.target).hide()
            for own user_id, follow of @follow_users
                if follow
                    $.ajax
                        type: 'POST'
                        url: '/api'
                        data:
                            method: 'POST'
                            path: '/friendships/create.json'
                            post_params: JSON.stringify
                                user_id: user_id

            @follow_users = {}

            setTimeout =>
                @current_page = 0
                @_requestSearch()
            , 1000

            return false



RTD.SearchPage = SearchPage
