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

        @_requestSearch()

    render: ->
        super()
        document.title = "#{@query} - #{@base_title}"

        $("#content").html(Jst.evaluate(RTD.layouts.results, this))


RTD.SearchPage = SearchPage
