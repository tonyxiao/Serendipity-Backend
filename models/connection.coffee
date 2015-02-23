
@Connections = new Mongo.Collection 'connections'
Connections.timestampable()

# MARK: - Schema Validation
Connections.attachSchema new SimpleSchema
  users: type: [Object]
  'users.$._id': type: String
  'users.$.notified': type: Boolean
  'users.$.lastMessageDate': type: Date, optional: true
  expiresAt: type: Date
  type:
    type: String
    allowedValues: ['yes', 'maybe']

# MARK - Instance Methods
Connections.helpers
  messages: ->
    Messages.find
      connectionId: @_id

  otherUser: (thisUser) ->
    userIds = _.pluck @users, '_id'
    if _.contains(userIds, thisUser._id)
      recipientId = _.without(userIds, thisUser._id)[0]
      return Users.findOne recipientId

  createNewMessage: (text, sender) ->
    # TODO: error handling if text is null
    recipient = @otherUser(sender)
    messageId = Messages.insert
      connectionId: @_id
      senderId: sender._id
      recipientId: recipient._id
      isUnread: true
      text: text

    Connections.update {_id: @_id},
      $set:
        lastMessageText: text
    # TODO: Update expiry, send push notification

  removeAllMessages: ->
    Messages.remove
      connectionId: @_id

  remove: ->
    Connections.remove @_id

  clientView: (refUser) ->
    view = _.clone this
    view.otherUserId = @otherUser(refUser)._id
    return view

Connections.nextExpirationDate = ->
  expiration = new Date
  expiration.setDate expiration.getDate() + 3 # 3 days from now
  return expiration
