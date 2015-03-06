

Meteor.publish 'messages', ->
  if @userId
    return Users.findOne(@userId).allMessages()

Meteor.publish 'currentUser', ->
  # TODO: Better implmentation of client view
  if @userId
    return Users.find(@userId)

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
          connection = Connections.findOne(connectionId)
          otherUser = connection.otherUser currentUser
          self.added 'connections', connection._id, connection.clientView(currentUser)
          self.added 'users', otherUser._id, otherUser.clientView()
          # keep track of who the connected user for removal purpose
          connectedUsers[connectionId] = otherUser._id
      removed: (connectionId) ->
        if !initializing
          self.removed 'connections', connectionId
          self.removed 'users', connectedUsers[connectionId]
          delete connectedUsers[connectionId]
      changed: (connectionId) ->
        if !initializing
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
      self.added 'users', otherUser._id, otherUser.clientView()
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
    handle = Users.findOne(@userId).candidateQueue().observeChanges
      added: (candidateId) ->
        if !initializing
          candidate = Candidates.findOne(candidateId)
          if candidate.vetted && candidate.active
            user = candidate.user()
            self.added 'candidates', candidateId, candidate.clientView()
            self.added 'users', user._id, user.clientView()
            usersByCandidate[candidateId] = user._id
      removed: (candidateId) ->
        if !initializing && usersByCandidate[candidateId]?
          self.removed 'candidates', candidateId
          self.removed 'users', usersByCandidate[candidateId]
          delete usersByCandidate[candidateId]

    initializing = false
    currentCandidates = Users.findOne(@userId).candidateQueue().fetch()
    currentCandidates.forEach (candidate) ->
      if candidate.vetted && candidate.active
        user = candidate.user()
        self.added 'candidates', candidate._id, candidate.clientView()
        self.added 'users', user._id, user.clientView()
        usersByCandidate[candidate._id] = user._id

    self.ready()
    @onStop ->
      handle.stop()
