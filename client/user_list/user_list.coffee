
Template.userList.helpers
  users: ->
    Users.find()

Template.userList.events
  'keyup #search': ->
    searchText = $('#search').val().toLowerCase()
    $(".user-list li a span").each () ->
      name = $(this).text().toLowerCase()

      listItem = $(this).parent().parent()
      if (name.indexOf(searchText) == -1)
        listItem.hide()
      else
        listItem.show()



