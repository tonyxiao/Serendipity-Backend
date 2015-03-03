
Template.userList.helpers
  users: ->
    Users.find()

Template.userList.events
  'keyup #search': ->
    searchText = $('#search').val()
    $(".user-list li a span").each () ->
      name = $(this).html()

      listItem = $(this).parent().parent()
      if (name.indexOf(searchText) == -1)
        listItem.hide()
      else
        listItem.show()



