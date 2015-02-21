
Meteor.methods
  populateCandidateQueue: (userId) ->
    user = Users.findOne(userId)
    if user
      user.populateCandidateQueue()