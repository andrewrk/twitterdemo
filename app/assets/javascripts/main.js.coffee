# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
#= require jquery.cookie
#= require jst

home_title = document.title

twitter_init =
    signed_in: false
    user_id: null
    screen_name: null
    avatar: null
    friends: null
    users: {} # cache of user data, indexed by id
    unfollow_users: {} # users we want to unfollow (id => true/undefined)

twitter = $.extend({}, twitter_init)

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
<% if (friends) { %>
  <h1>Followees</h1>
  <div class="followees">
  <% if (friends.length > 0) { %>
    #{pagination_layout}
    <% for (var i = 0; i < friends.length; i++) { %>
      <div class="followee<%= i % 2 === 0 ? '' : ' odd' %>">
        <div class="basic-info span-3">
          <img alt="" src="<%= friends[i].profile_image_url %>">
          <div>
            <a
              href="https://twitter.com/#!/<%= friends[i].screen_name %>"><%=
                  friends[i].name || friends[i].screen_name %></a>
          </div>
        </div>
        <div class="description span-12">
          <% if (friends[i].description) { %>
            <%= friends[i].description  %>
          <% } else { %>
            No description
          <% } %>
        </div>
        <div class="actions span-3">
          <input
            type="checkbox"
            data-id="<%= friends[i].id %>"
            class="unfollow"
            id="unfollow-<%= friends[i].id %>"
            <% if (unfollow_users[friends[i].id]) { %>
              checked="checked"
            <% } %>
          >
          <label for="unfollow-<%= friends[i].id %>">Unfollow</label>
        </div>
        <div class="clear"></div>
      </div>
    <% } %>
    <input type="button" value="Submit" class="submit">
    #{pagination_layout}
  <% } else { %>
    <p>You're not following anybody.</p>
  <% } %>
  </div>
<% } else { %>
  <p>Not signed in</p>
<% } %>
""")

getFriends = ->
    $.ajax
        type: 'POST'
        url: '/api'
        data:
            method: 'GET'
            path: '/friends/ids.json'
            get_params: JSON.stringify
                user_id: twitter.user_id
                cursor: -1
        success: (data) ->
            twitter.friends = data
            requestCurrentPage()

requestCurrentPage = ->
    start = home_data.current_page * home_data.results_per_page
    end = start + home_data.results_per_page
    friends = twitter.friends.ids[start...end]
    # fetch our user while we're at it
    friends.push(twitter.user_id)

    $.ajax
        type: 'POST'
        url: '/api'
        data:
            method: 'GET'
            path: '/users/lookup.json'
            get_params: JSON.stringify
                user_id: friends.join(',')
                include_entities: false
        success: (data) ->
            # merge the results into our cache
            for user in data
                twitter.users[user.id] = user

            updatePage()


updateHomePage = ->
    # prepare data
    if twitter.friends?
        start = home_data.current_page * home_data.results_per_page
        end = start + home_data.results_per_page
        context =
            friends: (twitter.users[id] for id in twitter.friends.ids[start...end])
            has_prev: start > 0
            has_next: end < twitter.friends.ids.length
            unfollow_users: twitter.unfollow_users
    else
        context = {friends: null}

    # render templates
    content = $("#content")
    content.html(Jst.evaluate(friends_template, context))
    
    # add hooks
    content.find(".nav-next").on 'click', (event) ->
        home_data.current_page += 1
        requestCurrentPage()
        return false

    content.find(".nav-prev").on 'click', (event) ->
        home_data.current_page -= 1
        # don't need to request old pages, they're already cached
        updatePage()
        return false

    content.find(".unfollow").on 'change', (event) ->
        id = $(this).data('id')
        is_checked = $(this).is(':checked')
        twitter.unfollow_users[id] = is_checked
        return false
    
    content.find(".submit").on 'click', (event) ->
        # unfollow every checked user one by one
        $(this).hide()
        for own user_id, unfollow of twitter.unfollow_users
            if unfollow
                $.ajax
                    type: 'POST'
                    url: '/api'
                    data:
                        method: 'POST'
                        path: '/friendships/destroy.json'
                        post_params: JSON.stringify
                            user_id: user_id
                            include_entities: false

        twitter.unfollow_users = {}

        setTimeout ->
            home_data.current_page = 0
            requestCurrentPage()
        , 1000

        return false

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
    $("#signout").on 'click', (event) ->
        # delete cookies
        $.cookie('user_id', null)
        $.cookie('screen_name', null)

        # delete local cache
        twitter = $.extend({}, twitter_init)

        # set url to home page
        history.pushState({}, '', "/")
        document.title = home_title
    
        # re-render templates
        updatePage()
        return false

    updateHomePage()

$(document).ready( ->
    updatePage()

    if twitter.signed_in
        getFriends()
)
