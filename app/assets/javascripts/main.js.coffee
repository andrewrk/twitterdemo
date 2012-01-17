#= require jquery.address-1.5
#= require homepage
#= require err404page
#= require searchpage

page = null
routes =
    '/': RTD.HomePage
    '/search': RTD.SearchPage

parseQuery = (query) ->
    obj = {}
    if not query?
        return obj
    for [param, val] in (valset.split('=') for valset in query.split('&'))
        obj[unescape(param)] = unescape(val)
    
    return obj

handleNewPage = (address) ->
    # choose the correct page to load
    [path, query] = address.split('?')

    PageClass = routes[path] or RTD.Err404Page

    page = new PageClass(parseQuery(query))
    page.render()

$.address.change (event) -> handleNewPage(event.value)

RTD.navToAddress = (address) ->
    force_update = $.address.value() == address
    $.address.value address
    location.hash = address

    if force_update
        handleNewPage address

