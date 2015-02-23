
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

  filterConnections: (active, type) ->
    # TODO: Make currentDate a reactive data source
    selector = 'users._id': @_id
    if active == true
      selector.expiresAt = $gt: CurrentDate.get()
    else if active == false
      selector.expiresAt = $lte: CurrentDate.get()
    if type?
      selector.type = type
    return Connections.find selector

  activeYesConnections: ->
    @filterConnections true, 'yes'

  expiredYesConnections: ->
    @filterConnections false, 'yes'

  activeMaybeConnections: ->
    @filterConnections true, 'maybe'

  expiredMaybeConnections: ->
    @filterConnections false, 'maybe'

  allConnections: ->
    @filterConnections()

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
      expiresAt: Connections.nextExpirationDate new Date
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

