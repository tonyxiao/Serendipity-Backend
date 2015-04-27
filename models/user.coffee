logger = new KetchLogger 'users'

@ACTIVE_DEVICE_ID = 'active_device'
@ACTIVE_DEVICE_DETAILS = 'active_device_details'

@Users = Meteor.users
Users.attachBehaviour('timestampable')

# TODO: use metadata schema to validate metadata
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
    type: [String]
    optional: true
  education:
    type: String
    optional: true
  email:
    type: String
    optional: true
  firstName:
    type: String
    optional: true
  gender:
    type: String
    optional: true
    allowedValues: ['male', 'female']
  genderPref:
    type: String
    optional: true
    allowedValues: ['men', 'women', 'both']
  height:
    type: Number
    optional: true
  lastName:
    type: String
    optional: true
  location:
    type: String
    optional: true
  metadata:
    type: Object
    blackbox: true
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

Meteor.users.attachSchema @UserSchema

# MARK: - Instance Methods
Users.helpers

  # Logs the user out from the server by clearing login tokens
  logout: ->
    modifier = {}
    modifier['services.resume.loginTokens'] = []
    Users.update @_id,
      $set: modifier

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
    @clearFromOtherUsersCandidateList()

  isVetted: ->
    @vetted? && @vetted == 'yes'

  isSnoozed: ->
    @vetted? && @vetted == 'snoozed'

  isBlocked: ->
    @vetted? && @vetted == 'blocked'

  isCrab: ->
    @_id == Meteor.settings.CRAB_USER_ID

  _isDeleted: ->
    @status? && @status == 'deleted'

  _unmarkAsDeleted: ->
    Users.update @_id,
      $unset: status : "active"

  markAsDeleted: ->
    if @isCrab()
      error =  new Meteor.Error(501, 'Exception: Cannot mark crab user as deleted')
      logger.error(error)
      throw error

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

  addDevice: (deviceId) ->
    if !@devices?
      @devices = []

    if @devices.indexOf(deviceId) < 0
      @devices.push deviceId

      Users.update @_id,
        $set: devices: @devices

  removeDevice: (deviceId) ->
    if @devices?
      @devices = _.reject @devices, (d) -> d == deviceId
    Users.update @_id,
      $set: devices: @devices

  deviceDetails: () ->
    Devices.find
      _id: $in: @devices

  # TODO: Make this generic
  sendTestPushMessage: (message) ->
    devices = Devices.find
      _id: $in: @devices
    _.each devices.fetch(), (device) ->
      # TODO: refactor this as part of device
      if device.pushToken? and device.pushToken != "" and device.apsEnv? and device.appId?
        PushService.sendTestMessage device.pushToken, device.apsEnv, device.appId, message

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

  vettedNotActiveCandidates: ->
    Candidates.find
      forUserId: @_id
      vetted: true
      active: $ne: true

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

    # TODO: refactor this with validation method in Connections
    otherUser = Users.findOne userId

    # validation checks for when a user connects to another (non-ketchy user
    if !@isCrab() and !otherUser.isCrab()
      if !@isVetted() or !otherUser? or !otherUser.isVetted()
        error = new Meteor.Error(500, "Please ensure that #{@._id} and #{otherUser._id} are vetted before inserting connection.")
        logger.error(error)
        throw error

    prompts = PromptService.prompts()
    prompt1Id = PromptService.getPrompt()
    prompt2Id = PromptService.getPrompt(prompt1Id)

    connectionUser1 = {}
    connectionUser1['_id'] = @_id
    connectionUser1['hasUnreadMessage'] = false

    connectionUser2 = {}
    connectionUser2['_id'] = userId
    connectionUser2['hasUnreadMessage'] = true

    if !@isCrab() and !otherUser.isCrab()
      connectionUser1['promptText'] = prompts[prompt1Id]
      connectionUser2['promptText'] = prompts[prompt2Id]

    connectionId = Connections.insert
      users: [
        connectionUser1
        connectionUser2
      ]
      expiresAt: Connections.nextExpirationDate new Date
      type: connectionType

    return connectionId

  connectWithUserAndSendMessage: (user, connectionType) ->
    connectionId = @connectWithUser(user._id, connectionType)
    user.sendTestPushMessage "It's a Ketch! #{@firstName} also thinks highly of you :)"
    return connectionId

  populateCandidateQueue: (maxCount) ->
    if @isCrab()
      error = new Meteor.Error(500, "Cannot populate candidates for crab user.")
    logger.error(error)
    throw error

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

  # Since we have no validation yet, a generic update method will do
  # Once we have validation, we should consider breaking out the separate cases of
  # updateAttribute.
  updateAttribute: (fieldName, value) ->
    logger.info "updating #{fieldName} with #{value} for user #{@_id}"
    modifier = {}
    modifier[fieldName] = value
    Users.update @_id,
      $set: modifier

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

  # TODO: refactor view generation code
  _clientView: (view) ->
    if !view?
      view = _.clone this

    delete view.genderPref
    delete view.email
    delete view.status
    delete view.vetted
    delete view.metadata
    delete view.services
    delete view.status
    delete view.roles
    delete view.nextRefreshTimestamp
    delete view.createdAt
    delete view.updatedAt
    delete view.devices
    delete view.timezone

    @_updateBirthdayInView(view)
    @_updatePhotoURLsInView(view)

    return view

  candidateView: ->
    view = @_clientView _.clone this
    delete view.lastName
    return view

  _addToSettings: (user, settings, key) ->
    if user[key]?
      settings[key] = user[key]

    return settings

  settingsView:  ->
    settings = {}

    # TODO: refactor this
    photoUrls = []
    @sortedPhotos().forEach (photo) ->
      if photo.active
        photoUrls.push(photo.url)
    settings.photoUrls = photoUrls

    settings = @_addToSettings(@, settings, 'education')
    settings = @_addToSettings(@, settings, 'about')
    settings = @_addToSettings(@, settings, 'genderPref')
    settings = @_addToSettings(@, settings, 'email')
    settings = @_addToSettings(@, settings, 'height')
    settings = @_addToSettings(@, settings, 'work')

    settings["vetted"] = @.isVetted()

    return settings

  view: ->
    view = @_clientView _.clone this
    return view
