
Meteor.methods
  populateCandidateQueue: (userId) ->
    user = Users.findOne(userId)
    if user
      user.populateCandidateQueue()

  forceInverseCandidateChoice: (candidateId, choice) ->
    candidate = Candidates.findOne(candidateId)
    if candidate
      candidate.forceChoiceForInverse(choice)
