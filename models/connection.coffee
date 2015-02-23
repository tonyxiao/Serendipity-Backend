
@Connections = new Mongo.Collection 'connections'
Connections.timestampable()

# MARK: - Schema Validation
Connections.attachSchema new SimpleSchema
  users: type: [Object]
  'users.$._id': type: String
  'users.$.notified': type: Boolean
  'users.$.lastMessageDate': type: Date, optional: true
  expiresAt: type: Date
  lastMessageText: type: String, optional: true
  type:
    type: String
    allowedValues: ['yes', 'maybe']

# MARK - Instance Methods
Connections.helpers

  isExpired: ->
    @expiresAt < CurrentDate.get()

  messages: ->
    Messages.find
      connectionId: @_id

  otherUser: (thisUser) ->
    userIds = _.pluck @users, '_id'
    if _.contains(userIds, thisUser._id)
      recipientId = _.without(userIds, thisUser._id)[0]
      return Users.findOne recipientId

  setUserKeyValue: (user, key, value) ->
    info = _.find @users, (u) -> u._id == user._id
    info[key]  = value
    selector = _id: @_id, 'users._id': user._id
    modifier = {}
    modifier["users.$.#{key}"] = value
    Connections.update selector, $set: modifier

  createNewMessage: (text, sender) ->
    # TODO: error handling if text is null
    Messages.insert
      connectionId: @_id
      senderId: sender._id
      recipientId: @otherUser(sender)._id
      isUnread: true
      text: text

    @setUserKeyValue sender, 'lastMessageDate', new Date

    # Compute the next expiration date
    expiresAt = @expireAt
    lastMessageDates = _.compact _.pluck(@users, 'lastMessageDate')
    if lastMessageDates.length == 2
      expiresAt = Connections.nextExpirationDate _.min(lastMessageDates)

    Connections.update @_id,
      $set:
        lastMessageText: text
        expiresAt: expiresAt
    # TODO: send push notification

  removeAllMessages: ->
    Messages.remove
      connectionId: @_id

  remove: ->
    Connections.remove @_id

  clientView: (refUser) ->
    view = _.clone this
    view.otherUserId = @otherUser(refUser)._id
    return view

Connections.nextExpirationDate = (relativeDate) ->
  expiration = new Date relativeDate.getTime()
  expiration.setDate expiration.getDate() + 3 # 3 days from now
  return expiration
