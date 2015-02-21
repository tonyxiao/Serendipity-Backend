
Template.home.helpers
  candidateQueue: ->
    if Meteor.user()
      Users.current().candidateQueue()