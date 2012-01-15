#= require page

class HomePage extends RTD.Page
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
    friends_template = Jst.compile """
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
  <% if (signed_in) { %>
    <p>Loading...</p>
  <% } else { %>
    <p>Not signed in</p>
  <% } %>
<% } %>
"""

    _requestCurrentPage: ->
        start = @current_page * @results_per_page
        end = start + @results_per_page
        friends = @friends.ids[start...end]
        # fetch our user while we're at it
        friends.push(@user_id)

        $.ajax
            type: 'POST'
            url: '/api'
            data:
                method: 'GET'
                path: '/users/lookup.json'
                get_params: JSON.stringify
                    user_id: friends.join(',')
                    include_entities: false
            success: (data) =>
                # merge the results into our cache
                for user in data
                    @users[user.id] = user

                @render()

    _requestFriends: ->
        $.ajax
            type: 'POST'
            url: '/api'
            data:
                method: 'GET'
                path: '/friends/ids.json'
                get_params: JSON.stringify
                    user_id: @user_id
                    cursor: -1
            success: (data) =>
                @friends = data
                @_requestCurrentPage()

    constructor: ->
        super()

        @current_page = 0
        @results_per_page = 20
        @friends = null
        @unfollow_users = {} # users we want to unfollow (id => true/not true)

        if @signed_in
            @_requestFriends()

    render: ->
        super()

        # prepare data
        if @friends?
            start = @current_page * @results_per_page
            end = start + @results_per_page
            context =
                friends: (@users[id] for id in @friends.ids[start...end])
                has_prev: start > 0
                has_next: end < @friends.ids.length
                unfollow_users: @unfollow_users
        else
            context = {friends: null}

        # render templates
        content = $("#content")
        content.html(Jst.evaluate(friends_template, context))
        
        # add hooks
        content.find(".nav-next").on 'click', (event) =>
            @current_page += 1
            @_requestCurrentPage()
            return false

        content.find(".nav-prev").on 'click', (event) =>
            @current_page -= 1
            # don't need to request old pages, they're already cached
            @render()
            return false

        content.find(".unfollow").on 'change', (event) =>
            checkbox = $(event.target)
            id = checkbox.data('id')
            is_checked = checkbox.is(':checked')
            @unfollow_users[id] = is_checked
            return false
        
        content.find(".submit").on 'click', (event) =>
            # unfollow every checked user one by one
            $(event.target).hide()
            for own user_id, unfollow of @unfollow_users
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

            @unfollow_users = {}

            setTimeout =>
                @current_page = 0
                @_requestCurrentPage()
            , 1000

            return false

RTD.HomePage = HomePage
