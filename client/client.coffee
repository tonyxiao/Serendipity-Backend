
Meteor.subscribe 'allUsers'
Meteor.subscribe 'allCandidates'
Meteor.subscribe 'allConnections'
Meteor.subscribe 'allMessages'

Template.home.helpers
  candidateQueue: ->
    if Meteor.user()
      Users.current().candidateQueue()