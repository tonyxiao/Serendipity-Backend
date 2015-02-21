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
      alert 'Not Implemented'

  'click .clear-queue': ->
    if confirm('sure?')
      alert 'Not Implemented'

  'click .say-yes': ->
    Meteor.call 'forceInverseCandidateChoice', @_id, 'yes'

  'click .say-no': ->
    Meteor.call 'forceInverseCandidateChoice', @_id, 'no'

  'click .say-maybe': ->
    Meteor.call 'forceInverseCandidateChoice', @_id, 'maybe'