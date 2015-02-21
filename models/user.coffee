
# Not sure why these hack is necessary. Probably because the packages are loaded *after*
# Meteor.users collection has already been created. Need to control package load order
# HACK ALERT: Maybe file issues?
# https://github.com/dburles/meteor-collection-helpers
# https://github.com/Sewdn/meteor-collection-behaviours
Meteor.users.helpers = Mongo.Collection.prototype.helpers
CollectionBehaviours.extendCollectionInstance(Meteor.users)

@Users = Meteor.users
Users.timestampable()


# MARK - Instance Methods
Users.helpers
  candidateQueue: ->
    candidates.find({
      matcherId: @_id
      choice: null
    }, {sort: {dateMatched: 1}})

  activeConnections: ->
    connections.find
      users:
        $in: [@_id]

  allMessages: ->
    return messages.find
      $or: [
        { senderId: userId }
        { recipientId: userId }
      ]

# MARK: - Class Methods
Users.current = ->
  Meteor.user()
