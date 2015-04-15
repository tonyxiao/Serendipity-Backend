logger = new KetchLogger 'publications'

Meteor.publish 'metadata', ->
  softMinBuild = {
    _id: 'softMinBuild',
    value: Meteor.settings.SOFT_MIN_BUILD
  }

  hardMinBuild = {
    _id: 'hardMinBuild',
    value: Meteor.settings.HARD_MIN_BUILD
  }

  crab = {
    _id: 'crabUserId',
    value: Meteor.settings.CRAB_USER_ID
  }

  this.added 'metadata', softMinBuild._id, softMinBuild
  this.added 'metadata', hardMinBuild._id, hardMinBuild
  this.added 'metadata', crab._id, crab

  if @userId
    self = this

    # special read-only collections
    user = Users.findOne @userId
    isVetted = {
      _id: 'vetted'
      value: user.isVetted()
    }
    this.added 'metadata', isVetted._id, isVetted

    cachedMetadata = {}
    initializing = true
    handle = Users.find(@userId,
      fields:
        metadata: 1).observeChanges(
      added: (userId, value) ->
        logger.info "metadata add for user #{userId} | #{JSON.stringify(value)}"

        # TODO: the right thing to do here is probably to figure out which value got added
        # patching this in to prevent server logs. Will investigate later.
        user = Users.findOne(userId)
        _.each user.metadata, (value, key) ->
          settings = {
            _id: key
            value: value
          }
          if !cachedMetadata[key]?
            self.added 'metadata', settings._id, settings

      removed: (userId) ->
        logger.info "metadata remove for user #{userId}"
      changed: (userId, value) ->
        logger.info "metadata change #{userId} | #{JSON.stringify(value)}"
        if !initializing
          _.each value.metadata, (metadataValue, metadataKey) ->
            MetadataSchema.objectKeys().forEach (fieldName) ->
              # update cache if metadataKey is valid and there either doesn't exist a mapping yet
              # or exists a different mapping
              if metadataKey == fieldName && (!cachedMetadata[metadataKey]? || cachedMetadata[metadataKey] != metadataValue)
                cachedMetadata[metadataKey] = metadataValue
                settings = {
                  _id: metadataKey
                  value: metadataValue
                }
                logger.info "changed #{metadataKey} from user #{userId} to value #{metadataValue}"
                self.changed 'metadata', metadataKey, settings
    )
    initializing = false

    if user.metadata?
      _.each user.metadata, (value, key) ->
        settings = {
          _id: key
          value: value
        }
        cachedMetadata[key] = value
        logger.info "initializing metadata for #{self.userId} with key #{key} to value #{JSON.stringify(settings)}"
        self.added 'metadata', settings._id, settings

    self.ready()
    @onStop ->
      handle.stop()

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
