# TODO: Remove DEBUG ONLY subscription
Meteor.subscribe 'allUsers'
Meteor.subscribe 'allCandidates'
Meteor.subscribe 'allConnections'
Meteor.subscribe 'allMessages'

Template.userList.helpers
  users: ->
    Users.find()

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


Template.userConnections.helpers
  readableType: ->
    if @type == 'yes'
      return 'marry'
    if @type == 'maybe'
      return 'keep'
    return ''

  currentUser: ->
    Template.parentData()

  otherUser: ->
    @otherUser(Template.parentData())

Template.userConnections.events
  'click .remove-connection': ->
    Meteor.call 'connection/remove', @_id