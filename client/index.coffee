# TODO: Remove DEBUG ONLY subscription
Meteor.subscribe 'allUsers'
Meteor.subscribe 'allCandidates'
Meteor.subscribe 'allConnections'
Meteor.subscribe 'allMessages'

Template.userList.helpers
  users: ->
    Users.find()

Template.userDetails.events
  'click .update-fb-access-token': ->
    accessToken = $('#fb-access-token').val()
    Users.update @_id, $set: 'services.facebook.accessToken': accessToken

  'click .clear-photos': ->
    Meteor.call 'user/clearPhotos', @_id

  'click .reload-fb-photos': ->
#    if confirm('sure?')
    Meteor.call 'user/reloadPhotosFromFacebook', @_id

Template.userCandidates.events
  'click .populate-queue': ->
    if confirm('sure?')
      Meteor.call 'user/populateCandidateQueue', @_id

  'click .clear-queue': ->
    if confirm('sure?')
      Meteor.call 'user/clearCandidateQueue', @_id

  'click .say-yes': ->
    Meteor.call 'candidate/forceInverseCandidateChoice', @_id, 'yes'

  'click .say-no': ->
    Meteor.call 'candidate/forceInverseCandidateChoice', @_id, 'no'

  'click .say-maybe': ->
    Meteor.call 'candidate/forceInverseCandidateChoice', @_id, 'maybe'

  'click .make-connection': ->
    Meteor.call 'candidate/makeConnection', @_id


Template.userConnectionList.helpers
  currentUser: ->
    Template.parentData(2)

  otherUser: ->
    @otherUser(Template.parentData(2))


Template.userConnections.events
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
