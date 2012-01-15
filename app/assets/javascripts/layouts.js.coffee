#= require jst-0.5.0

window.RTD ||= {}
RTD.layouts ||= {}

RTD.layouts.pagination = """
<div class="paginator">
  <% if (has_prev) { %>
    <a href="#" class="nav-prev">&laquo; Prev</a>
  <% } %>
  <% if (has_next) { %>
    <a href="#" class="nav-next">Next &raquo;</a>
  <% } %>
</div>
"""

RTD.layouts.results = Jst.compile """
<% if (results) { %>
  <h1><%= label %></h1>
  <div class="profiles">
  <% if (results.length > 0) { %>
    #{RTD.layouts.pagination}
    <% for (var i = 0; i < results.length; i++) { %>
      <div class="profile<%= i % 2 === 0 ? '' : ' odd' %>">
        <div class="basic-info span-3">
          <img alt="" src="<%= results[i].profile_image_url %>">
          <div>
            <a
              href="https://twitter.com/#!/<%= results[i].screen_name %>"><%=
                  results[i].name || results[i].screen_name %></a>
          </div>
        </div>
        <div class="description span-12">
          <% if (results[i].description) { %>
            <%= results[i].description  %>
          <% } else { %>
            No description
          <% } %>
        </div>
        <div class="actions span-3">
          <input
            type="checkbox"
            data-id="<%= results[i].id %>"
            class="action"
            id="action-<%= results[i].id %>"
            <% if (action_checked[results[i].id]) { %>
              checked="checked"
            <% } %>
          >
          <label for="action-<%= results[i].id %>"><%= action_label %></label>
        </div>
        <div class="clear"></div>
      </div>
    <% } %>
    <input type="button" value="Submit" class="submit">
    #{RTD.layouts.pagination}
  <% } else { %>
    <p>No results.</p>
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

RTD.layouts.nav = Jst.compile """
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
    <input
        name="q"
        type="text"
        placeholder="Search"
        class="search"
        value="<%= query %>"
    >
  </li>
</ul>
"""

