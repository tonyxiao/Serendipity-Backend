
Template._connectionList.helpers
  thisUser: ->
    Template.parentData(2)

  otherUser: ->
    @otherUser(Template.parentData(2))

Template._connectionList.events
  'click .remove-connection': ->
    Meteor.call 'connection/remove', @_id

  'click .set-expire-days': (event) ->
    days = parseFloat $(event.target).next('.expire-days').val()
    Meteor.call 'connection/setExpireDays', @_id, days

Template.userConnections.events
  'click .clear-all-connections': ->
    console.log this
    Meteor.call 'user/clearAllConnections', @_id
