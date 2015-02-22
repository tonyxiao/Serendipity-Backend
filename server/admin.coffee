
Meteor.methods
  'user/clearPhotos': (userId) ->
    user = Users.findOne userId
    if user?
      user.clearPhotos()

  'user/reloadPhotosFromFacebook': (userId) ->
    user = Users.findOne userId
    if user?
      user.reloadPhotosFromFacebook()

  'user/populateCandidateQueue': (userId) ->
    user = Users.findOne userId
    if user?
      user.populateCandidateQueue()

  'user/clearCandidateQueue': (userId) ->
    user = Users.findOne userId
    if user?
      user.clearCandidateQueue()

  'candidate/forceInverseCandidateChoice': (candidateId, choice) ->
    candidate = Candidates.findOne candidateId
    if candidate?
      candidate.forceChoiceForInverse(choice)

  'candidate/makeConnection': (candidateId) ->
    # TODO: Replace makeConnection with the actual game mechanic
    candidate = Candidates.findOne candidateId
    if candidate?
      console.log "Connecting #{candidate.forUser().firstName} with #{candidate.user().firstName}"
      candidate.forUser().connectWithUser candidate.user(), _.sample(['yes', 'maybe'])

  'connection/remove': (connectionId) ->
    connection = Connections.findOne connectionId
    if connection?
      connection.removeAllMessages()
      connection.remove()