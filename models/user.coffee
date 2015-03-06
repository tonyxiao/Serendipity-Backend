
# Not sure why these hack is necessary. Probably because the packages are loaded *after*
# Meteor.users collection has already been created. Need to control package load order
# HACK ALERT: Maybe file issues?
# https://github.com/dburles/meteor-collection-helpers
# https://github.com/Sewdn/meteor-collection-behaviours
Meteor.users.helpers = Mongo.Collection.prototype.helpers
CollectionBehaviours.extendCollectionInstance(Meteor.users)

@Users = Meteor.users
Users.timestampable()

# TODO: Add schema validation for user model

# MARK: - Instance Methods
Users.helpers

  profilePhotoUrl: ->
    return _.first @photoUrls

  getDevice: (deviceId) ->
    _.find @devices, (d) -> d._id == deviceId

  addDevice: (device) ->
    # TODO: Add validation for _id, pushToken, appId, apnEnvironment

    if not @devices?
      @devices = []
    existingDevice = @getDevice device._id
    if existingDevice?
      # Modify in-memory
      _.extend existingDevice, device
      # Modify in-db
      selector = _id: @_id, 'devices._id': device._id
      modifier = _.object _.map device, (value, key) ->
        ["users.$.#{key}", value]
      Users.update selector, $set: modifier
    else
      @devices.push device
      Users.update @_id, $push: devices: device

  removeDevice: (device) ->
    if @devices?
      @devices = _.reject @devices, (d) -> d._id == device._id
    Users.update @_id,
      $pull: devices: _id: device._id

  updateNextRefreshTimestamp: ->
    intervalMillis = Meteor.settings.REFRESH_INTERVAL or 86400000 # 24 hours
    updatedTimeUTC = @nextRefreshTimestamp.getMilliseconds() + intervalMillis

    @nextRefreshTimestamp.setMilliseconds(updatedTimeUTC)
    console.log @firstName + " -> " + @nextRefreshTimestamp


    Users.update @_id,
      $set: nextRefreshTimestamp : @nextRefreshTimestamp


  # TODO: Make this generic
  sendTestPushMessage: (message) ->
    _.each @devices, (device) ->
      PushService.sendTestMessage device.pushToken, device.apnEnvironment, device.appId, message

  previousCandidates: ->
    Candidates.find
      forUserId: @_id
      choice: $ne: null

  candidateQueue: ->
    Candidates.find {
      forUserId: @_id
      choice: null
      vetted: true
    }, {sort: dateMatched: 1}

  allCandidates: ->
    Candidates.find forUserId: @_id

  filterConnections: (type, expired) ->
    selector = 'users._id': @_id
    if expired
      selector.expired = true
    else
      selector.expired = $ne : true
    if type?
      selector.type = type
    return Connections.find selector

  activeConnections: ->
    selector = 'users._id': @_id
    selector.expired = $ne: true
    return Connections.find selector

  activeYesConnections: ->
    @filterConnections 'yes'

  expiredYesConnections: ->
    @filterConnections 'yes', true

  activeMaybeConnections: ->
    @filterConnections 'maybe'

  expiredMaybeConnections: ->
    @filterConnections 'maybe', true

  allConnections: ->
    selector = 'users._id': @_id
    return Connections.find selector

  allMessages: ->
    Messages.find
      $or: [
        { senderId: @_id }
        { recipientId: @_id }
      ]

  addUserAsCandidate: (userId) ->
    # TODO: Handle error, make more efficient
    candidate = Candidates.findOne
      forUserId: @_id
      userId: userId

    if candidate?
      Candidates.insert
        forUserId: @_id
        userId: userId
        vetted: false

  vetCandidate: (userId) ->
    candidate = Candidates.findOne
      forUserId: @_id
      userId: userId

    if candidate?
      Candidates.update
        forUserId: @_id
        userId: userId
        { $set: { vetted: true }}

  getVettedCandidates: (numCandidates) ->
    Candidates.find({
      forUserId: @_id
    }, {
      limit: numCandidates
    })

  connectWithUser: (user, connectionType) ->
    connectionId = Connections.insert
      users: [
        {_id: @_id, hasUnreadMessage: false}
        {_id: user._id, hasUnreadMessage: true}
      ]
      expiresAt: Connections.nextExpirationDate new Date
      type: connectionType

    user.sendTestPushMessage "It's a Ketch! #{@firstName} also thinks highly of you :)"
    return connectionId

  populateCandidateQueue: (maxCount) ->
    MatchService.generateMatchesForUser this, maxCount

  getCandidateQueue: ->
    candidates = Candidates.find
      forUserId: @_id
      active: true

    return candidates.fetch()

  reloadPhotosFromFacebook: ->
    new FacebookPhotoService(Meteor.settings.AZURE_CONTAINER).importPhotosForUser this

  clearPhotos: ->
    Users.update @_id, $unset: photoUrls: ''

  clearCandidateQueue: ->
    Candidates.remove
      forUserId: @_id
      choice: null

  clearAllCandidates: ->
    Candidates.remove forUserId: @_id

  clearPreviousCandidates: ->
    Candidates.remove
      forUserId: @_id
      choice: $ne: null

  clearAllConnections: ->
    @clearAllMessages()
    Connections.remove 'users._id': @_id

  clearAllMessages: ->
    Messages.remove
      $or: [
        { senderId: @_id }
        { recipientId: @_id }
      ]

  # TODO: make "superclass" helpers that does create, remove, update, etc
  remove: ->
    Users.remove @_id

  clientView: ->
    view = _.clone this
    delete view.services
    return view

