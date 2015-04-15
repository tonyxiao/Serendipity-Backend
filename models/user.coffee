logger = new KetchLogger 'users'

# Not sure why these hack is necessary. Probably because the packages are loaded *after*
# Meteor.users collection has already been created. Need to control package load order
# HACK ALERT: Maybe file issues?
# https://github.com/dburles/meteor-collection-helpers
# https://github.com/Sewdn/meteor-collection-behaviours
Meteor.users.helpers = Mongo.Collection.prototype.helpers
CollectionBehaviours.extendCollectionInstance(Meteor.users)

@Users = Meteor.users
Users.timestampable()

@DeviceSchema = new SimpleSchema
  _id:
    type: String
    min: 1 # not empty
  appId:
    type: String
    min: 1 # not empty
  apnEnvironment:
    type: String
    min: 1 # not empty
  pushToken:
    type: String
    min: 1 # not empty
  updatedAt: type: Date

@MetadataSchema = new SimpleSchema
  bugfenderId:
    type: String
    optional: true
  gameTutorialMode:
    type: Boolean
    optional: true
  hasBeenWelcomed:
    type: Boolean
    optional: true
  debugState:
    type: String
    optional: true

# TODO: schema validation for devices, photos, etc
@UserSchema = new SimpleSchema
  about:
    type: String
    optional: true
  age:
    type: Number
    optional: true
  devices:
    type: [@DeviceSchema]
    optional: true
  education:
    type: String
    optional: true
  firstName:
    type: String
    optional: true
  gender:
    type: String
    optional: true
    allowedValues: ['male', 'female']
  lastName:
    type: String
    optional: true
  location:
    type: String
    optional: true
  metadata:
    type: @MetadataSchema
    optional: true
  nextRefreshTimestamp:
    type: Date
    optional: true
  photos:
    type: [Object]
    optional: true
    blackbox: true
  services:
    type: Object
    optional: true
    blackbox: true
  status: # TODO: status should be in user metadata.
    type: String
    optional: true
    allowedValues: ['deleted', 'active']
  roles:
    type: [String]
    optional: true
  vetted: # TODO: vetted should be in user metadata.
    type: String
    optional: true
    allowedValues: ['yes', 'blocked', 'snoozed']
  work:
    type: String
    optional: true

Users.attachSchema @UserSchema

# MARK: - Instance Methods
Users.helpers

  # mark this user as having joined the ketch community
  vet: ->
    Users.update @_id,
      $set: vetted: "yes"

  block: ->
    @_changeVetStatus "blocked"

  snooze: ->
    @_changeVetStatus "snoozed"

  _changeVetStatus: (vetStatus) ->
    Users.update @_id,
      $set: vetted: vetStatus
    @clearAllCandidates()
    @clearFromOtherUsersCandidateList()
    @clearAllConnections()

  isVetted: ->
    @vetted? && @vetted == 'yes'

  isSnoozed: ->
    @vetted? && @vetted == 'snoozed'

  isBlocked: ->
    @vetted? && @vetted == 'blocked'

  _isDeleted: ->
    @status? && @status == 'deleted'

  _unmarkAsDeleted: ->
    Users.update @_id,
      $unset: status : "active"

  markAsDeleted: ->
    Users.update @_id,
      $set: status: 'deleted'

    # expire the connections
    selector = 'users._id': @_id
    Connections.update selector,
      $set:
        expired: true

    # deactivate the candidates
    Candidates.find({ $or: [{forUserId: @_id}, {userId: @_id}] }).fetch().forEach (candidate) ->
      candidate.unvet()

  profilePhotoUrl: ->
    if @photos? and @photos.length > 0
      photo = _.first @sortedActivePhotos()
      if photo?
        return photo.url

    return null

  sortedActivePhotos: ->
    activePhotos = @sortedPhotos().filter (element) ->
      return element.active == true
    return activePhotos

  sortedPhotos: ->
    photos = _.clone @photos
    photos.sort (a,b) ->
      return a.order > b.order
    return photos

  getDevice: (deviceId) ->
    _.find @devices, (d) -> d._id == deviceId

  addDevice: (device) ->
    if not @devices?
      @devices = []
    existingDevice = @getDevice device._id
    if existingDevice?
      # Modify in-db - remove it so that we can push again.
      Users.update @_id, $pull: devices: existingDevice

      # Modify in-memory
      _.extend existingDevice, device


    @devices.push device
    Users.update @_id, $push: devices: device

  removeDevice: (device) ->
    if @devices?
      @devices = _.reject @devices, (d) -> d._id == device._id
    Users.update @_id,
      $pull: devices: _id: device._id

  # TODO: Make this generic
  sendTestPushMessage: (message) ->
    firstName = @firstName
    _.each @devices, (device) ->
      if device.pushToken? and device.pushToken != "" and device.apnEnvironment? and device.appId?
        PushService.sendTestMessage device.pushToken, device.apnEnvironment, device.appId, message

  updateNextRefreshTimestamp: ->
    intervalMillis = Meteor.settings.REFRESH_INTERVAL_MILLIS
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

  snoozedCandidates: ->
    Candidates.find {
      forUserId: @_id
      choice: 'maybe'
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
    if userId == Meteor.settings.CRAB_USER_ID
      error =  new Meteor.Error(501, 'Excepton: Attempting to create crab as candidate')
      logger.error(error)
      throw error

    # TODO: Handle error, make more efficient
    candidate = Candidates.findOne
      forUserId: @_id
      userId: userId

    if !candidate?
      candidateUser = Users.findOne userId

      if @isBlocked() || candidateUser.isBlocked()
        error = new Meteor.Error(500, "Trying to add blocked user to candidate queue <#{@_id}, #{userId}>.")
        logger.error(error)
        throw error

      # Candidates can only be generated when both users are vetted
      if candidateUser? && candidateUser.isVetted()
        Candidates.insert
          forUserId: @_id
          userId: userId
          vetted: false
          active: false
      else
        error = new Meteor.Error(500, "Ensure  <#{userId}> is vetted before adding to queue of <#{@_id}>")
        logger.error(error)
        throw error

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

  connectWithUser: (userId, connectionType) ->
    # make sure connection doesnt already exist.
    existingConnection = Connections.find
      $and: [
        { 'users._id' : userId }
        { 'users._id' : @_id}
      ]

    if existingConnection.fetch().length != 0
      error = new Meteor.Error(500, "Trying to connect #{userId} with #{@_id} but connection exists.")
      logger.error(error)
      throw error

    connectionId = Connections.insert
      users: [
        {_id: @_id, hasUnreadMessage: false}
        {_id: userId, hasUnreadMessage: true}
      ]
      expiresAt: Connections.nextExpirationDate new Date
      type: connectionType

    return connectionId

  connectWithUserAndSendMessage: (user, connectionType) ->
    connectionId = @connectWithUser(user._id, connectionType)
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

  clearFromOtherUsersCandidateList: ->
    Candidates.remove userId: @_id

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

  _modifyPhotoActiveState: (url, value) ->
    @photos.forEach (photo) ->
      if (photo.url == url)
        photo.active = value

    Users.update @_id,
      $set: photos: @photos

  _activatePhoto: (url) ->
    @_modifyPhotoActiveState(url, true)

  _deactivatePhoto: (url) ->
    @_modifyPhotoActiveState(url, false)

  # view changes for all clients
  _updateBirthdayInView: (view) ->
    birthday = {}
    if view.birthday?
      birthday.month = view.birthday.getMonth() + 1
      birthday.day = view.birthday.getDate()
    view.birthday = birthday

  _updatePhotoURLsInView: (view) ->
    photoUrls = []
    view.sortedPhotos().forEach (photo) ->
      if photo.active
        photoUrls.push(photo.url)
    view.photoUrls = photoUrls
    delete view.photos

  _clientView: (view) ->
    if !view?
      view = _.clone this

    delete view.status
    delete view.vetted
    delete view.metadata
    delete view.services

    @_updateBirthdayInView(view)
    @_updatePhotoURLsInView(view)

    return view

  candidateView: ->
    view = @_clientView _.clone this
    delete view.lastName
    return view

  view: ->
    view = @_clientView _.clone this
    return view
