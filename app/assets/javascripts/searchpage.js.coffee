#= require page

class SearchPage extends RTD.Page
    constructor: ->
        super()
        @base_title = "Search - " + @base_title

    render: ->
        super()
        document.title = @base_title

RTD.SearchPage = SearchPage
