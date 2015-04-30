process.env.ROOT_URL = 'https://ketch.herokuapp.com'

# Helpers
@insertVettedUser = () ->
  return Users.insert
    vetted: 'yes'

@insertVettedCandidate = (forUserId) ->
  userId = insertVettedUser()
  return Candidates.insert
    forUserId: forUserId
    userId: userId
    vetted: true
    active: false

@insertActiveCandidate = (forUserId) ->
  candidateId = insertVettedCandidate(forUserId)
  Candidates.findOne(candidateId).activate()

@createMockDevice = (id) ->
  return Devices.insert
    _id: id
    pushToken: id
    apsEnv: id
    appId: id

@createMockUserWithDevice = (id, gender = 'male', genderPref='women') ->
  deviceId = createMockDevice(id)

  return Users.insert
    nextRefreshTimestamp: new Date(1)
    device_ids: [deviceId]
    vetted: 'yes'
    gender: gender
    genderPref: genderPref

@insertUnexpiredConnection =  (userId1, userId2, expiresAtTimestamp) ->
  return Connections.insert
    users: [
      { _id: userId1, hasUnreadMessage: false}
      {_id: userId2, hasUnreadMessage: false}]
    expired: false
    expiresAt: expiresAtTimestamp
    type: 'yes'