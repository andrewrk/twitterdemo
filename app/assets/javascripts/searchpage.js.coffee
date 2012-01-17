#= require page

class SearchPage extends RTD.ResultsAndActionPage
    requestCurrentPage: ->
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
                # merge the results into our cache
                for user in data
                    @users[user.id] = user
                @results = data
                @render()

    constructor: (params) ->
        super(params)

        @base_title = "Search - " + @base_title
        @query = params.q
        @terms = @query.split(/\s+/)
        @completed_action_label = "Follow results"
        @api_path = '/friendships/create.json'

        @requestCurrentPage()

    canonicalUrl: ->
        if @completed_actions?
            return "/#/results"
        else
            return "/#/search?q=#{escape(@query)}&page=#{@current_page}"

    getCurrentPageContext: ->
        completed_actions: null
        results: @results
        has_prev: @current_page > 1
        has_next: @results.length == @results_per_page
        action_checked: @action_users
        action_label: "Follow"
        label: "Search Results"

    render: ->
        super()
        document.title = "#{@query} - #{@base_title}"


RTD.SearchPage = SearchPage
