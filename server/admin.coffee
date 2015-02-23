
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

  'user/clearAllConnections': (userId) ->
    user = Users.findOne userId
    if user?
      user.clearAllConnections()

  'candidate/makeChoice': (candidateId, choice) ->
    candidate = Candidates.findOne candidateId
    if candidate?
      candidate.makeChoice choice

  'candidate/makeChoiceForInverse': (candidateId, choice) ->
    candidate = Candidates.findOne candidateId
    if candidate?
      candidate.makeChoiceForInverse choice

  'candidate/remove': (candidateId) ->
    candidate = Candidates.findOne candidateId
    if candidate?
      candidate.remove()

  'candidate/createInverse': (candidateId) ->
    candidate = Candidates.findOne candidateId
    if candidate?
      candidate.createInverse()

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

  'import/tinder': (jsonText) ->
    data = JSON.parse(jsonText)
    FixtureService.importFromTinder jsonText