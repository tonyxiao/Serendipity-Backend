DEBUG = Meteor.settings.DEBUG
console.log "debug: #{DEBUG}"

Meteor.publish 'metadata', ->
  currentUser = Users.findOne @userId

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
    user = Users.findOne @userId

    isVetted = {
      _id: 'vetted'
      value: user.isVetted()
    }

    this.added 'metadata', isVetted._id, isVetted

  this.ready()

Meteor.publish 'messages', ->
  if @userId
    return Users.findOne(@userId).allMessages()

Meteor.publish 'currentUser', ->
  if DEBUG
    console.log "sending currentUser"

  if @userId
    self = this

    initializing = true
    handle = Users.find(@userId).observeChanges(
      added: (userId) ->
        console.log "publishing 'added' for #{userId}."
      removed: (userId) ->
        console.log "publishing 'removed' for #{userId}. This shouldn't be possible?"
      changed: (userId) ->
        self.changed 'users', userId, Users.findOne(userId).view()
    )
    initializing = false

    user = Users.findOne(@userId).view()

    self.added 'users', @userId, user

    if DEBUG
      console.log "sent currentUser #{@userId}"
      console.log user

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
  if DEBUG
    console.log "publishing connections"

  if @userId
    currentUser = Users.findOne @userId
    self = this

    if DEBUG
      console.log "publishing connections for current user #{@userId}"

    # a dictionary of connection_id to connected user
    connectedUsers = {}
    initializing = true
    handle = Users.findOne(@userId).activeConnections().observeChanges(
      added: (connectionId) ->
        if !initializing
          connection = Connections.findOne(connectionId)
          otherUser = connection.otherUser currentUser
          self.added 'connections', connection._id, connection.clientView(currentUser)
          self.added 'users', otherUser._id, otherUser.view()
          # keep track of who the connected user for removal purpose
          connectedUsers[connectionId] = otherUser._id

          if DEBUG
            console.log "adding conection #{connectionId}"

      removed: (connectionId) ->
        if !initializing
          self.removed 'connections', connectionId
          self.removed 'users', connectedUsers[connectionId]
          delete connectedUsers[connectionId]

          if DEBUG
            console.log "removing conection #{connectionId}"

      changed: (connectionId) ->
        if !initializing
          connection = Connections.findOne(connectionId)

          if DEBUG
            console.log "changing conection #{connectionId}"

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
  console.log "publishing candidates"

  if @userId

    if DEBUG
      console.log "publishing connections for current user #{@userId}"

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

          if DEBUG
            console.log "adding candidate #{candidateId}"

      removed: (candidateId) ->
        if !initializing && usersByCandidate[candidateId]?
          self.removed 'candidates', candidateId
          self.removed 'users', usersByCandidate[candidateId]
          delete usersByCandidate[candidateId]

          if DEBUG
            console.log "removing candidate #{candidateId}"

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
