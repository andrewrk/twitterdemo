# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
#= require jquery.cookie
$(document).ready( ->
    user_id = $.cookie('user_id')
    $.ajax({
        type: 'POST'
        url: '/api'
        data: {
            method: 'GET'
            path: "/friends/ids.json"
            get_params: JSON.stringify({
                user_id: user_id
                cursor: -1
            })
        }
    })
)
