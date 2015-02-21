
Meteor.methods
  'user/populateCandidateQueue': (userId) ->
    user = Users.findOne(userId)
    if user
      user.populateCandidateQueue()

  'user/clearCandidateQueue': (userId) ->
    user = Users.findOne(userId)
    if user
      user.clearCandidateQueue()

  'candidate/forceInverseCandidateChoice': (candidateId, choice) ->
    candidate = Candidates.findOne(candidateId)
    if candidate
      candidate.forceChoiceForInverse(choice)

  'candidate/makeConnection': (candidateId) ->
    candidate = Candidates.findOne(candidateId)
    if candidate
      console.log "Connecting #{candidate.forUser().firstName} with #{candidate.user().firstName}"
      candidate.forUser().connectWithUser(candidate.user())