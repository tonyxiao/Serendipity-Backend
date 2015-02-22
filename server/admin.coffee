
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

  'candidate/makeChoice': (candidateId, choice) ->
    candidate = Candidates.findOne candidateId
    if candidate?
      candidate.makeChoice choice

  'candidate/forceInverseCandidateChoice': (candidateId, choice) ->
    candidate = Candidates.findOne candidateId
    if candidate?
      candidate.forceChoiceForInverse(choice)

  'connection/remove': (connectionId) ->
    connection = Connections.findOne connectionId
    if connection?
      connection.removeAllMessages()
      connection.remove()

  'connection/sendMessageAs': (userId, connectionId, text) ->
    connection = Connections.findOne connectionId
    sender = Users.findOne userId
    if connection? and sender?
      connection.createNewMessage text, sender
