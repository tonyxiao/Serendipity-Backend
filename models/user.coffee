
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

  # mark this user as having joined the ketch community
  vet: ->
    Users.update @_id,
      $set: vetted: "yes"

  unVet: ->
    Users.update @_id,
      $set: vetted: "no"

  block: ->
    Users.update @_id,
      $set: vetted: "blocked"

  snooze: ->
    Users.update @_id,
      $set: vetted: "snoozed"

  isVetted: ->
    @vetted? && @vetted == "yes"

  isSnoozed: ->
    @vetted? && @vetted == "snoozed"

  isBlocked: ->
    @vetted? && @vetted == "blocked"

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

  # TODO: Make this generic
  sendTestPushMessage: (message) ->
    _.each @devices, (device) ->
      PushService.sendTestMessage device.pushToken, device.apnEnvironment, device.appId, message

  updateNextRefreshTimestamp: ->
    intervalMillis = (Meteor.settings && Meteor.settings.REFRESH_INTERVAL_MILLIS) or 86400000 # 24 hours
    @nextRefreshTimestamp.setTime(@nextRefreshTimestamp.getTime() + intervalMillis)

    @setNextRefreshTimestamp(@nextRefreshTimestamp)

  setNextRefreshTimestamp: (timestamp) ->
    Users.update @_id,
      $set: nextRefreshTimestamp : timestamp

  # all candidates for which the user had made a choice
  previousCandidates: ->
    Candidates.find
      forUserId: @_id
      choice: $ne: null

  # all candidates who are vetted and who the user has not currently made a choice for
  candidateQueue: ->
    Candidates.find {
      forUserId: @_id
      choice: null
      vetted: true
    }, {sort: dateMatched: 1}

  # all candidates for this user
  allCandidates: ->
    Candidates.find
      forUserId: @_id

  # (debug) ordered list of candidates to display on the user candidates debug screen.
  allCandidatesWithoutDecision: ->
    Candidates.find {
      forUserId: @_id
      choice: null
    }, { sort:
      active: -1
      vetted: -1
      choice: 1
      dateMatched: 1}

  # candidates which have the active flag flipped on.
  activeCandidates: ->
    candidates = Candidates.find
      forUserId: @_id
      vetted: true
      active: true
      choice: null

  addUserAsCandidate: (userId) ->
    console.log "adding " + userId + " as candidate for " + @firstName

    # TODO: Handle error, make more efficient
    candidate = Candidates.findOne
      forUserId: @_id
      userId: userId

    if !candidate?
      Candidates.insert
        forUserId: @_id
        userId: userId
        vetted: false
        active: false

  vettedCandidates: (numCandidates) ->
    Candidates.find({
      forUserId: @_id
      vetted: true
    }, {
      limit: numCandidates
    })

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

  updateBirthday: (month, day) ->
    user = Users.findOne @_id
    user.birthday.setMonth(month - 1)
    user.birthday.setDate(day)

    Users.update @_id,
      $set: birthday: user.birthday

  # TODO: make "superclass" helpers that does create, remove, update, etc
  remove: ->
    Users.remove @_id

  # view changes for all clients
  _clientView: (view) ->
    if !view?
      view = _.clone this

    delete view.services

    birthday = {}
    if view.birthday?
      birthday.month = view.birthday.getMonth() + 1
      birthday.day = view.birthday.getDate()
    view.birthday = birthday

    return view

  connectionView: ->
    view = @_clientView _.clone this
    delete view.lastName
    return view

  candidateView: ->
    view = @_clientView _.clone this
    delete view.services
    return view


