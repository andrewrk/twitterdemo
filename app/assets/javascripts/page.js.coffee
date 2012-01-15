#= require jquery.cookie
#= require jst-0.5.0

base_title = document.title
class Page
    nav_template = Jst.compile('''
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
      <a class="signout" href="#">Sign out</a>
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
''')

    _cacheSignInState: ->
        @user_id = $.cookie('user_id')
        @screen_name = $.cookie('screen_name')
        @signed_in = @user_id? and @screen_name?

        if @users[@user_id]?
            @avatar = @users[@user_id].profile_image_url

    constructor: ->
        @signed_in = false
        @user_id = null
        @screen_name = null
        @avatar = null
        @users = {} # cache of user data, indexed by id
        @base_title = base_title

        @_cacheSignInState()

    render: ->
        # prepare data
        @_cacheSignInState()

        # render templates
        nav = $("#nav")
        nav.html(Jst.evaluate(nav_template, this))

        # add hooks
        nav.find(".signout").on 'click', (event) =>
            # delete cookies
            $.cookie('user_id', null)
            $.cookie('screen_name', null)

            # set url to home page
            RTD.navToAddress '/'
            return false
        
        nav.find(".search").on 'keydown', (event) =>
            if event.keyCode == 13
                # navigate to search page
                query = escape($(event.target).val())
                RTD.navToAddress "search?q=#{query}"
                return false
            return true

window.RTD ||= {}
RTD.Page = Page
