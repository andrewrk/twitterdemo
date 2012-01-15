# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
#= require jquery.cookie
#= require jst

home_title = document.title
twitter =
    signed_in: false
    user_id: null
    screen_name: null

nav_template = Jst.compile('''
<form action="search" method="get">
  <ul>
    <% if (signed_in) { %>
      <li>
        <a href="https://twitter.com/#!/<%= screen_name %>"><%= screen_name %></a>
      </li>
      <li>
        <a id="signout" href="#">Sign out</a>
      </li>
    <% } else { %>
      <li>
        <a href="/signin">Sign in</a>
      </li>
    <% } %>
    <li>
      <input name="q" type="text" placeholder="Search" class="search">
    </li>
  </ul>
</form>
''')

getFriends = ->
    $.ajax({
        type: 'POST'
        url: '/api'
        data: {
            method: 'GET'
            path: '/friends/ids.json'
            get_params: JSON.stringify({
                user_id: twitter.user_id
                cursor: -1
            })
        }
    })

updatePage = ->
    # prepare data
    twitter.user_id = $.cookie('user_id')
    twitter.screen_name = $.cookie('screen_name')
    twitter.signed_in = twitter.user_id? and twitter.screen_name?

    # render templates
    $("nav").html(Jst.evaluate(nav_template, twitter))

    # add hooks
    $("#signout").on('click', ->
        # delete cookies
        $.cookie('user_id', null)
        $.cookie('screen_name', null)

        # set url to home page
        history.pushState({}, '', "/")
        document.title = home_title
    
        # re-render templates
        updatePage()
        return false
    )

$(document).ready( ->
    updatePage()

    if twitter.signed_in
        getFriends()
)
