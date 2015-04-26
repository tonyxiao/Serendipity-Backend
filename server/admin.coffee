logger = new KetchLogger 'admin'

# TODO: Consider prefixing admin methods with /admin
Meteor.methods
  'admin/user/addPushToken': (userId, pushToken) ->
    # TODO: Convert this method into more generic addDevice
    user = Users.findOne userId
    if user?
      Devices.insert
        appId: 'co.ketchy.ketch'
        apnEnvironment: 'development'
        pushToken: pushToken
        updatedAt: new Date

  'admin/device/remove': (userId, deviceId) ->
    console.log "removing device #{userId}, #{deviceId}"
    user = Users.findOne userId
    if user?
      user.removeDevice deviceId

  'admin/user/sendPushMessage': (userId, pushMessage) ->
    user = Users.findOne userId
    if user?
      user.sendTestPushMessage pushMessage

  'admin/user/remove': (userId) ->
    Users.remove userId

  'admin/user/vet': (userId) ->
    user = Users.findOne userId
    user.vet()

  'admin/user/snooze': (userId) ->
    user = Users.findOne userId
    user.snooze()

  'admin/user/blockFromKetch': (userId) ->
    user = Users.findOne userId
    user.block()

  'admin/user/edit': (userId, userInfo) ->
    try
      userInfo = JSON.parse userInfo

      Users.update userId,
        $set: userInfo
      logger.info "user #{userId} edited"
    catch e
      error = new Meteor.Error(400, 'Exception: Unable to import. Likely malformed json');
      logger.error(error)
      throw error

  'admin/user/delete': (userId) ->
    user = Users.findOne userId
    if user?
      user.markAsDeleted()

  'admin/user/photo/reset': (userId) ->
    user = Users.findOne userId
    photos = user.photos
    i = 0
    photos.forEach (photo) ->
      photo.order = i
      i++
    Users.update userId,
      $set: photos: photos

  'admin/user/photo/swap': (userId, fromOrderNumber, toOrderNumber) ->
    user = Users.findOne userId
    photos = user.photos

    if user? && 0 <= fromOrderNumber < photos.length && 0 <= toOrderNumber < photos.length
      photos.forEach (photo) ->
        if photo.order == toOrderNumber
          photo.order = fromOrderNumber
        else if photo.order == fromOrderNumber
          photo.order = toOrderNumber
      Users.update userId,
        $set: photos: photos
    else
      error = new Meteor.Error(500, 'Exception: Cannot swap photos are you sure you are swapping valid image indices?');
      logger.error(error)
      throw error

  'admin/user/delete/restore': (userId) ->
    user = Users.findOne userId
    if user?
      user._unmarkAsDeleted()

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

  'user/photo/activate': (userId, url) ->
    user = Users.findOne userId
    if user?
      user._activatePhoto(url)

  'user/photo/deactivate': (userId, url) ->
    user = Users.findOne userId
    if user?
      user._deactivatePhoto(url)

  'candidate/makeChoice': (candidateId, choice) ->
    candidate = Candidates.findOne candidateId
    if candidate?
      candidate.activate()
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
      connection.markAsReadFor user

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
      error = new Meteor.Error(400, 'Exception: Unable to import. Likely malformed json')
      logger.error(error)
      throw error
