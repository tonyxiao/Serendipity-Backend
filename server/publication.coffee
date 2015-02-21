

Meteor.publish 'messages', ->
  if @userId
    return Users.findOne(@userId).allMessages()

Meteor.publish 'currentUser', ->
  if @userId
    return buildUser(Users.find(@userId))

