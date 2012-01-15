#= require page

class SearchPage extends RTD.Page
    constructor: (params) ->
        super(params)
        @base_title = "Search - " + @base_title
        @query = params.q

    render: ->
        super()
        document.title = @base_title
        alert @query

RTD.SearchPage = SearchPage
