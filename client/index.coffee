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

Template.userCandidateList.events
  'click .remove-candidate': ->
    Meteor.call 'candidate/remove', @_id
    
  'click .my-choice .say-yes': ->
    Meteor.call 'candidate/makeChoice', @_id, 'yes'

  'click .my-choice .say-no': ->
    Meteor.call 'candidate/makeChoice', @_id, 'no'

  'click .my-choice .say-maybe': ->
    Meteor.call 'candidate/makeChoice', @_id, 'maybe'

  'click .their-choice .say-yes': ->
    Meteor.call 'candidate/makeChoiceForInverse', @_id, 'yes'

  'click .their-choice .say-no': ->
    Meteor.call 'candidate/makeChoiceForInverse', @_id, 'no'

  'click .their-choice .say-maybe': ->
    Meteor.call 'candidate/makeChoiceForInverse', @_id, 'maybe'


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
