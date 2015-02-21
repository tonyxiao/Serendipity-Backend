
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
    return @photos[0] # TODO: Rename photos to photoUrls, or make them embedded dictionaries

  previousCandidates: ->
    Candidates.find
      forUserId: @_id
      choice: $ne: null

  candidateQueue: ->
    Candidates.find {
      forUserId: @_id
      choice: null
    }, {sort: dateMatched: 1}

  activeConnections: ->
    Connections.find
      users:
        $in: [@_id]

  allMessages: ->
    Messages.find
      $or: [
        { senderId: userId }
        { recipientId: userId }
      ]

  addUserAsCandidate: (user) ->
    # TODO: Handle error, make more efficient
    Candidates.insert
      forUserId: @_id
      userId: user._id
    Users.update @_id,
      $push:
        previousCandidateUserIds: user._id

  connectWithUser: (user) ->
    Connections.insert
      userIds: [@_id, user._id]
      messageIds: []

  populateCandidateQueue: (maxCount) ->
    # TODO: When logic is more fancy make this into a service
    maxCount ?= 12 # Default to 12 max
    ineligibleUserIds = _.map @previousCandidates().fetch(), (candidate) -> candidate.userId
    ineligibleUserIds.push @_id

    nextUsers = Users.find({
      _id: $nin: ineligibleUserIds
    }, {
      limit: maxCount
      fields: _id: 1
    }).fetch()

    for user in nextUsers
      @addUserAsCandidate user

    return nextUsers.length


# MARK: - Class Methods
Users.current = ->
  Meteor.user()
