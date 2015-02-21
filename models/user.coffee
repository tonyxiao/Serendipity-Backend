
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
    return _.first @photoUrls # TODO: Rename photos to photoUrls, or make them embedded dictionaries

  previousCandidates: ->
    Candidates.find
      forUserId: @_id
      choice: $ne: null

  candidateQueue: ->
    Candidates.find {
      forUserId: @_id
      choice: null
    }, {sort: dateMatched: 1}

  allConnections: ->
    Connections.find
      users:
        $in: [@_id]

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

  connectWithUser: (user) ->
    Connections.insert
      userIds: [@_id, user._id]
      messageIds: []

  populateCandidateQueue: (maxCount) ->
    nextUsers = MatchService.generateMatchesForUser(this, maxCount)
    for user in nextUsers
      @addUserAsCandidate(user)

  clearAllCandidates: ->
    Candidates.remove forUserId: @_id

  clearAllConnections: ->
    @clearAllMessages()
    Connections.remove users: $in: [@_id]

  clearAllMessages: ->
    Messages.remove
      $or: [
        { senderId: @_id }
        { recipientId: @_id }
      ]

  clientView: ->
    view = _.clone this
    delete view.services
    return view

# MARK: - Class Methods
# TODO: This is really not that helpful, consider removing
Users.current = ->
  Meteor.user()
