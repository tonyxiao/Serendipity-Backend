
Template.userConnectionList.helpers
  currentUser: ->
    Template.parentData(2)

  otherUser: ->
    @otherUser(Template.parentData(2))


Template.userConnections.events
  'click .clear-all-connections': ->
    console.log this
    Meteor.call 'user/clearAllConnections', @_id

  'click .remove-connection': ->
    Meteor.call 'connection/remove', @_id


Template.userConnectionDetails.helpers
  readableType: (connection) ->
    if connection.type == 'yes'
      return 'marry'
    if connection.type == 'maybe'
      return 'keep'
    return ''

Template.userConnectionDetails.events
  'click .send-message': ->
    text = $('#new-message').val()
    Meteor.call 'connection/sendMessageAs', @thisUser._id, @connection._id, text
    $('#new-message').val('') # Clear text field
