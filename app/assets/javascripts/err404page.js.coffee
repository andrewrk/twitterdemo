#= require page

class Err404Page extends RTD.Page
    template = Jst.compile '''
<h1>Page not found</h1>
<p>
    Don't know what you're looking for. You can try the
    <a href="#">home page</a>.
</p>
'''

    constructor: (params) ->
        super(params)
        @base_title = "Page not found - " + @base_title

    render: ->
        super()
        document.title = @base_title
        $("#content").html(Jst.evaluate(template, {}))

RTD.Err404Page = Err404Page
