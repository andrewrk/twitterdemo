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
    avatar: null
    friends: null
    users: {} # cache of user data, indexed by id

home_data =
    current_page: 0
    results_per_page: 20

nav_template = Jst.compile('''
<form action="search" method="get">
  <ul>
    <% if (signed_in) { %>
      <% if (avatar) { %>
        <li>
          <img alt="" src="<%= avatar %>" class="avatar-sm">
        </li>
      <% } %>
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

pagination_layout = '''
<div class="paginator">
  <% if (has_prev) { %>
    <a href="#" class="nav-prev">&laquo; Prev</a>
  <% } %>
  <% if (has_next) { %>
    <a href="#" class="nav-next">Next &raquo;</a>
  <% } %>
</div>
'''
friends_template = Jst.compile("""
<h1>Followees</h1>
<div class="followees">
<% if (friends.length > 0) { %>
  #{pagination_layout}
  <% for (var i = 0; i < friends.length; i++) { %>
    <div class="followee<%= i % 2 === 0 ? '' : ' odd' %>">
      <div class="basic-info span-3">
        <img alt="" src="<%= friends[i].profile_image_url %>">
        <div>
          <a href="https://twitter.com/#!/<%= friends[i].screen_name %>"><%= friends[i].name || friends[i].screen_name %></a>
        </div>
      </div>
      <div class="description span-12">
        <%= friends[i].description || '&nbsp;' %>
      </div>
      <div class="actions span-3">
        <input type="checkbox" class="unfollow" id="unfollow-<%= friends[i].id %>">
        <label for="unfollow-<%= friends[i].id %>">Unfollow</label>
      </div>
      <div class="clear"></div>
    </div>
  <% } %>
  #{pagination_layout}
<% } else { %>
  <p>You're not following anybody.</p>
<% } %>
</div>
""")

getFriends = ->
    $.ajax(
        type: 'POST'
        url: '/api'
        data:
            method: 'GET'
            path: '/friends/ids.json'
            get_params: JSON.stringify(
                user_id: twitter.user_id
                cursor: -1
            )
        success: (data) ->
            twitter.friends = data
            requestCurrentPage()
    )

requestCurrentPage = ->
    start = home_data.current_page * home_data.results_per_page
    end = start + home_data.results_per_page
    friends = twitter.friends.ids[start...end]
    # fetch our user while we're at it
    friends.push(twitter.user_id)

    $.ajax(
        type: 'POST'
        url: '/api'
        data:
            method: 'GET'
            path: '/users/lookup.json'
            get_params: JSON.stringify(
                user_id: friends.join(',')
                include_entities: false
            )
        success: (data) ->
            # merge the results into our cache
            for user in data
                twitter.users[user.id] = user

            updateHomePage()
    )


updateHomePage = ->
    updatePage()

    # prepare data
    start = home_data.current_page * home_data.results_per_page
    end = start + home_data.results_per_page
    
    context =
        friends: (twitter.users[id] for id in twitter.friends.ids[start...end])
        has_prev: start > 0
        has_next: end < twitter.friends.ids.length

    # render templates
    $("#content").html(Jst.evaluate(friends_template, context))
    
    # add hooks
    $("#content").find(".nav-next").on('click', ->
        home_data.current_page += 1
        requestCurrentPage()
        return false
    )
    $("#content").find(".nav-prev").on('click', ->
        home_data.current_page -= 1
        # don't need to request old pages, they're already cached
        updateHomePage()
        return false
    )

updatePage = ->
    # prepare data
    twitter.user_id = $.cookie('user_id')
    twitter.screen_name = $.cookie('screen_name')
    twitter.signed_in = twitter.user_id? and twitter.screen_name?

    if twitter.users[twitter.user_id]?
        twitter.avatar = twitter.users[twitter.user_id].profile_image_url

    # render templates
    $("#nav").html(Jst.evaluate(nav_template, twitter))

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
