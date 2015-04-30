logger = new KetchLogger 'publications'

class @DeviceService
  @isDebugLoginEnabled: (user, deviceId) ->
    isDebugLoginEnabled = undefined
    devices = user.devices()
    if devices? and devices.length > 0
      devices.forEach (device) ->
        if device._id == deviceId and device.settings? and device.settings.debugLoginMode? and !isDebugLoginEnabled?
          isDebugLoginEnabled =  device.settings.debugLoginMode

    return isDebugLoginEnabled


Meteor.publish 'settings', ->
  self = this
  connectionId = this.connection.id

  # userId to user settings properties (i.e. about, education)
  cache = {}
  settings = _.clone(Meteor.settings.public)
  
  # TODO: refactor devices into its own table.
  usersWithDevice = Users.find
    'devices._id': SessionData.getFromConnection(connectionId, ACTIVE_DEVICE_ID)
  usersWithDevice.observeChanges(
    added: (userId) ->
      deviceId = SessionData.getFromConnection(connectionId, ACTIVE_DEVICE_ID)
      if deviceId?
        user = Users.findOne(userId)

        debugLoginEnabeld = DeviceService.isDebugLoginEnabled(user, deviceId)
        setting = {
          _id: 'debugLoginMode'
          value: debugLoginEnabeld
        }

        if debugLoginEnabeld? and !cache[deviceId]?
          cache[deviceId] = debugLoginEnabeld
          logger.info "added settings: #{JSON.stringify(setting)}"
          self.added 'settings', setting._id, setting
        else if debugLoginEnabeld? and cache[deviceId] != debugLoginEnabeld
          cache[deviceId] = debugLoginEnabeld
          logger.info "changed settings: #{JSON.stringify(setting)}"
          self.changed 'settings', setting._id, setting
  )

  if @userId
    currentUserCursor = Users.find(@userId,
      fields:
        about: 1
        education: 1
        email: 1
        genderPref: 1
        height: 1
        photos: 1
        vetted: 1
        work: 1)

    currentUserSettings = Users.findOne(@userId).settingsView()
    _.extend settings, currentUserSettings

    handle = currentUserCursor.observeChanges(
      added: (userId, user) ->
        user = Users.findOne userId
        _.each user.settingsView(), (value, key) ->
          setting = {
            _id: key
            value: value
          }
          cache[key] = value

          logger.info "adding settings for #{self.userId}. <#{key}, #{value}>"
          self.added 'settings', setting._id, setting

      removed: (userId) ->
        # should never be triggered?
        logger.info "settings remove for user #{userId}. Not publishing"

      changed: (userId, changedValues) ->
        logger.info "settings change #{userId} | #{JSON.stringify(changedValues)}"

        user = Users.findOne userId
        _.each user.settingsView(), (value, key) ->
          setting = {
            _id: key
            value: value
          }

          if !cache[key]?
            logger.info "settings change. unexpected add #{userId} | <#{key}, #{value}>"
            cache[key] = value
            self.added 'settings', setting._id, setting
          else if cache[key] != value
            cache[key] = value
            logger.info "settings change #{userId} | <#{key}, #{value}>"
            self.changed 'settings', setting._id, setting
      )
    initializing = false
    @onStop ->
      handle.stop()

  # initialize by serving 'added' for everything in metadata
  _.each settings, (value, key) ->
    setting = {
      _id: key
      value: value
    }
    cache[key] = value
    logger.info "initializing settings. <#{key}, #{value}>"
    self.added 'settings', setting._id, setting

  self.ready()

Meteor.publish 'metadata', ->
  self = this

  metadata = {}
  cache = {}
  if @userId
    user = Users.findOne @userId
    if user.metadata?
      _.extend metadata, user.metadata

    initializing = true
    handle = Users.find(@userId,
      fields:
        metadata: 1).observeChanges(
      added: (userId, value) ->
        _.each value.metadata, (value, key) ->
          settings = {
            _id: key
            value: value
          }
          cache[key] = value

          logger.info "adding metadata for #{self.userId}. <#{key}, #{value}>"
          self.added 'metadata', settings._id, settings

      removed: (userId) ->
        # should never be triggered?
        logger.info "metadata remove for user #{userId}"

      changed: (userId, value) ->
        logger.info "metadata change #{userId} | #{JSON.stringify(value)}"
        _.each value.metadata, (value, key) ->
          if cache[key] != value
            settings = {
              _id: key
              value: value
            }

            isChange = cache[key]?
            cache[key] = value

            if isChange
              self.changed 'metadata', settings._id, settings
            else
              self.added 'metadata', settings._id, settings
    )
    initializing = false
    @onStop ->
      handle.stop()

  # initialize by serving 'added' for everything in metadata
  _.each metadata, (value, key) ->
    settings = {
      _id: key
      value: value
    }
    cache[key] = value

    logger.info "initializing metadata. <#{key}, #{value}>"
    self.added 'metadata', settings._id, settings

  self.ready()


Meteor.publish 'messages', ->
  if @userId
    return Users.findOne(@userId).allMessages()

Meteor.publish 'currentUser', ->
  if @userId
    self = this

    initializing = true
    handle = Users.find(@userId,
      fields:
        metadata: 0,
        updatedAt: 0).observeChanges(
      added: (userId) ->
        logger.info "publishing 'added' for #{userId}."
      removed: (userId) ->
        logger.info "publishing 'removed' for #{userId}. This shouldn't be possible?"
      changed: (userId) ->
        logger.info "publishing 'changed' for #{userId}."
        self.changed 'users', userId, Users.findOne(userId).view()
    )
    initializing = false

    self.added 'users', @userId, Users.findOne(@userId).view()
    self.ready()
    @onStop ->
      handle.stop()

#
# Publishes topic called 'connections' which populates a client side collection called
# 'connections' with {@code Meteor.connection} instances for all of the current user's
# connections. Simultaneously, publishes to the "users" collection with the
# {@code Meteor.user} corresponding to those connections.
#
Meteor.publish 'connections', ->
  if @userId
    currentUser = Users.findOne @userId
    self = this

    # a dictionary of connection_id to connected user
    connectedUsers = {}
    initializing = true
    handle = Users.findOne(@userId).activeConnections().observeChanges(
      added: (connectionId) ->
        if !initializing
          logger.info "connection #{connectionId} added"
          connection = Connections.findOne(connectionId)
          otherUser = connection.otherUser currentUser
          self.added 'connections', connection._id, connection.clientView(currentUser)
          self.added 'users', otherUser._id, otherUser.view()
          # keep track of who the connected user for removal purpose
          connectedUsers[connectionId] = otherUser._id
      removed: (connectionId) ->
        if !initializing
          logger.info "connection #{connectionId} removed"
          self.removed 'connections', connectionId
          self.removed 'users', connectedUsers[connectionId]
          delete connectedUsers[connectionId]
      changed: (connectionId) ->
        if !initializing
          logger.info "connection #{connectionId} changed"
          connection = Connections.findOne(connectionId)
          if connection.isExpired()
            self.removed 'connections', connectionId
            self.removed 'users', connectedUsers[connectionId]
            delete connectedUsers[connectionId]
          else
            self.changed 'connections', connection._id, connection.clientView(currentUser)
    )
    initializing = false

    currentUserConnections = Users.findOne(@userId).activeConnections().fetch()
    currentUserConnections.forEach (connection) ->
      otherUser = connection.otherUser currentUser
      self.added 'connections', connection._id, connection.clientView(currentUser)
      self.added 'users', otherUser._id, otherUser.view()
      connectedUsers[connection._id] = otherUser._id

    self.ready()
    @onStop ->
      handle.stop()

###*
# Publishes topic called 'matches' which populates a client side collection called
# 'matches' with {@code Meteor.matches} instances for all of the current user's
# connections. Simultaneously, publishes to the "users" collection with the
# {@code Meteor.user} corresponding to those matches.
###

Meteor.publish 'candidates', ->
  if @userId
    self = this
    # a dictionary of match_id to matched user
    usersByCandidate = {}
    initializing = true
    handle = Users.findOne(@userId).activeCandidates().observeChanges
      added: (candidateId) ->
        if !initializing
          candidate = Candidates.findOne candidateId
          user = candidate.user()
          self.added 'candidates', candidateId, candidate.clientView()
          self.added 'users', user._id, user.candidateView()
          usersByCandidate[candidateId] = user._id
      removed: (candidateId) ->
        if !initializing && usersByCandidate[candidateId]?
          self.removed 'candidates', candidateId
          self.removed 'users', usersByCandidate[candidateId]
          delete usersByCandidate[candidateId]

    initializing = false
    currentCandidates = Users.findOne(@userId).activeCandidates().fetch()
    currentCandidates.forEach (candidate) ->
      user = candidate.user()
      self.added 'candidates', candidate._id, candidate.clientView()
      self.added 'users', user._id, user.candidateView()
      usersByCandidate[candidate._id] = user._id

    self.ready()
    @onStop ->
      handle.stop()
