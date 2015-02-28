
@Connections = new Mongo.Collection 'connections'
Connections.timestampable()

# MARK: - Schema Validation
Connections.attachSchema new SimpleSchema
  users: type: [Object]
  'users.$._id': type: String
  'users.$.hasUnreadMessage': type: Boolean
  'users.$.lastSentDate': type: Date, optional: true
  expiresAt: type: Date
  lastMessageText: type: String, optional: true
  type:
    type: String
    allowedValues: ['yes', 'maybe']

# MARK - Instance Methods
Connections.helpers

  isExpired: ->
    @expired

  messages: ->
    Messages.find
      connectionId: @_id

  otherUser: (thisUser) ->
    userIds = _.pluck @users, '_id'
    if _.contains(userIds, thisUser._id)
      recipientId = _.without(userIds, thisUser._id)[0]
      return Users.findOne recipientId

  getUserInfo: (user) ->
    _.find @users, (u) -> u._id == user._id

  setUserKeyValue: (user, key, value) ->
    # First modify in memory
    info = @getUserInfo user
    info[key]  = value
    # Then modify in db
    selector = _id: @_id, 'users._id': user._id
    modifier = {}
    modifier["users.$.#{key}"] = value
    Connections.update selector, $set: modifier

  createNewMessage: (text, sender) ->
    # TODO: error handling if text is null
    recipient = @otherUser sender
    Messages.insert
      connectionId: @_id
      senderId: sender._id
      recipientId: recipient._id
      isUnread: true
      text: text

    @setUserKeyValue sender, 'lastSentDate', new Date
    @setUserKeyValue recipient, 'hasUnreadMessage', true

    # Compute the next expiration date
    expiresAt = @expireAt
    lastSentDates = _.compact _.pluck(@users, 'lastSentDate')
    if lastSentDates.length == 2
      expiresAt = Connections.nextExpirationDate _.min(lastSentDates)

    Connections.update @_id,
      $set:
        lastMessageText: text
        expiresAt: expiresAt

    recipient.sendTestPushMessage "#{sender.firstName}: #{text}"

  removeAllMessages: ->
    Messages.remove
      connectionId: @_id

  remove: ->
    Connections.remove @_id

  clientView: (refUser) ->
    view = _.clone this
    view.otherUserId = @otherUser(refUser)._id
    view.hasUnreadMessage = @getUserInfo(refUser).hasUnreadMessage
    delete view.users
    return view

Connections.nextExpirationDate = (relativeDate) ->
  expiration = new Date relativeDate.getTime()
  expiration.setDate expiration.getDate() + 3 # 3 days from now
  return expiration
