
Template._connectionList.helpers
  thisUser: ->
    Template.parentData(2)

  otherUser: ->
    @otherUser(Template.parentData(2))

Template._connectionList.events
  'click .remove-connection': ->
    Meteor.call 'connection/remove', @_id

  'click .set-expire-days': (event) ->
    days = parseInt $(event.target).next('.expire-days').val()
    Meteor.call 'connection/setExpireDays', @_id, days

Template.userConnections.events
  'click .clear-all-connections': ->
    console.log this
    Meteor.call 'user/clearAllConnections', @_id

Template.userConnectionDetails.helpers
  readableType: (connection) ->
    if connection.type == 'yes'
      return 'marry'
    if connection.type == 'maybe'
      return 'keep'
    return ''

  firstName: (userId) ->
    Users.findOne(userId).firstName

Template.userConnectionDetails.events
  'click .send-message': ->
    text = $('#new-message').val()
    Meteor.call 'connection/sendMessageAs', @thisUser._id, @connection._id, text
    $('#new-message').val('') # Clear text field

  'click .set-expire-days': ->
    days = parseInt $('#expire-days').val()
    Meteor.call 'connection/setExpireDays', @connection._id, days
