#= require jquery.address-1.5
#= require homepage
#= require err404page
#= require searchpage

page = null
routes =
    '/': RTD.HomePage
    '/search': RTD.SearchPage

handleNewPage = (address) ->
    # choose the correct page to load
    [path, query] = address.split('?')
    
    PageClass = routes[path] or RTD.Err404Page

    delete page
    page = new PageClass
    page.render()

$.address.change (event) -> handleNewPage(event.value)

RTD.navToAddress = (address) ->
    if $.address.value() == address
        handleNewPage address
    else
        $.address.value address
