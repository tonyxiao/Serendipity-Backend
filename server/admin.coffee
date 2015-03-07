# TODO: Consider prefixing admin methods with /admin
Meteor.methods
  'admin/user/addPushToken': (userId, pushToken) ->
      # TODO: Convert this method into more generic addDevice
    user = Users.findOne userId
    if user?
      user.addDevice
        _id: pushToken
        appId: 'co.ketchy.ketch'
        apnEnvironment: 'development'
        pushToken: pushToken
        updatedAt: new Date

  'admin/user/removePushToken': (userId, pushToken) ->
    # TODO: Convert this method into more generic addDevice
    user = Users.findOne userId
    if user?
      user.removeDevice _id: pushToken

  'admin/user/sendPushMessage': (userId, pushMessage) ->
    user = Users.findOne userId
    if user?
      user.sendTestPushMessage pushMessage

  'admin/user/remove': (userId) ->
    Users.remove userId

  'admin/globallySetNextRefresh': (UTCMillisSinceEpoch) ->
    matchService = MatchService.getMatchService()
    matchService.pause()

    nextRefreshDate = new Date UTCMillisSinceEpoch
    Users.update {},
      { $set: nextRefreshTimestamp : nextRefreshDate}
      { multi: true }

    matchService.unpause()

  'user/clearPhotos': (userId) ->
    user = Users.findOne userId
    if user?
      user.clearPhotos()

  'user/reloadPhotosFromFacebook': (userId) ->
    user = Users.findOne userId
    if user?
      user.reloadPhotosFromFacebook()

  'user/populateCandidateQueue': (userId, numCandidates) ->
    user = Users.findOne userId
    if user?
      user.populateCandidateQueue(numCandidates)

  'user/clearCandidateQueue': (userId) ->
    user = Users.findOne userId
    if user?
      user.clearCandidateQueue()

  'user/clearPreviousCandidates': (userId) ->
    user = Users.findOne userId
    if user?
      user.clearPreviousCandidates()

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

  'candidate/new': (forUserId, candidateUserId) ->
    forUser = Users.findOne forUserId
    forUser.addUserAsCandidate(candidateUserId)

  'candidate/vet': (candidateId) ->
    candidate = Candidates.findOne candidateId
    if candidate?
      candidate.vet()

  'candidate/unvet': (candidateId) ->
    candidate = Candidates.findOne candidateId
    if candidate?
      candidate.unvet()

  'candidate/activate': (candidateId) ->
    candidate = Candidates.findOne candidateId
    if candidate?
      candidate.activate()

  'candidate/deactivate': (candidateId) ->
    candidate = Candidates.findOne candidateId
    if candidate?
      candidate.deactivate()

  'connection/remove': (connectionId) ->
    connection = Connections.findOne connectionId
    if connection?
      connection.removeAllMessages()
      connection.remove()

  'connection/sendMessageAs': (connectionId, userId, text) ->
    connection = Connections.findOne connectionId
    sender = Users.findOne userId
    if connection? and sender?
      connection.createNewMessage text, sender

  'connection/markAsReadFor': (connectionId, userId) ->
    connection = Connections.findOne connectionId
    user = Users.findOne userId
    if connection? and user?
      connection.setUserKeyValue user, 'hasUnreadMessage', false

  'connection/setExpireDays': (connectionId, expireDays) ->
    expiresAt = new Date
    expiresAt.setTime(expiresAt.getTime() + expireDays * 24 * 60 * 60 * 1000)

    expired = expiresAt < new Date

    Connections.update connectionId,
      $set:
        expiresAt: expiresAt
        expired: expired

  'import/tinder': (jsonText) ->
    try
      FixtureService.importFromTinder JSON.parse jsonText
    catch error
      console.log error
      throw new Meteor.Error(400, 'Unable to import', 'Likely malformed json');
