
Meteor.methods
  populateCandidateQueue: (userId) ->
    user = Users.findOne(userId)
    if user
      user.populateCandidateQueue()

  forceInverseCandidateChoice: (candidateId, choice) ->
    candidate = Candidates.findOne(candidateId)
    if candidate
      candidate.forceChoiceForInverse(choice)

# Houston Admin setup
Houston.add_collection Meteor.users
Houston.add_collection Houston._admins