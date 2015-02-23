
# Not sure why these hack is necessary. Probably because the packages are loaded *after*
# Meteor.users collection has already been created. Need to control package load order
# HACK ALERT: Maybe file issues?
# https://github.com/dburles/meteor-collection-helpers
# https://github.com/Sewdn/meteor-collection-behaviours
Meteor.users.helpers = Mongo.Collection.prototype.helpers
CollectionBehaviours.extendCollectionInstance(Meteor.users)

@Users = Meteor.users
Users.timestampable()


# MARK: - Instance Methods
Users.helpers

  profilePhotoUrl: ->
    return _.first @photoUrls

  previousCandidates: ->
    Candidates.find
      forUserId: @_id
      choice: $ne: null

  candidateQueue: ->
    Candidates.find {
      forUserId: @_id
      choice: null
    }, {sort: dateMatched: 1}

  allCandidates: ->
    Candidates.find forUserId: @_id

  # TODO: Refactor yes, maybe and all connections to be more generic
  yesConnections: ->
    Connections.find
      'users._id': @_id
      type: 'yes'

  maybeConnections: ->
    Connections.find
      'users._id': @_id
      type: 'maybe'

  allConnections: ->
    Connections.find 'users._id': @_id

  allMessages: ->
    Messages.find
      $or: [
        { senderId: @_id }
        { recipientId: @_id }
      ]

  addUserAsCandidate: (user) ->
    # TODO: Handle error, make more efficient
    Candidates.insert
      forUserId: @_id
      userId: user._id

  connectWithUser: (user, connectionType) ->
    Connections.insert
      users: [
        {_id: @_id, notified: true}
        {_id: user._id, notified: false}
      ]
      expiresAt: Connections.nextExpirationDate()
      type: connectionType

  populateCandidateQueue: (maxCount) ->
    MatchService.generateMatchesForUser this, maxCount

  reloadPhotosFromFacebook: ->
    FacebookPhotoService.importPhotosForUser this

  clearPhotos: ->
    Users.update @_id, $unset: photoUrls: ''

  clearCandidateQueue: ->
    Candidates.remove
      forUserId: @_id
      choice: null

  clearAllCandidates: ->
    Candidates.remove forUserId: @_id

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
