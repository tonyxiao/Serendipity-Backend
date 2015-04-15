
@Connections = new Mongo.Collection 'connections'
Connections.timestampable()

# MARK: - Schema Validation
Connections.attachSchema new SimpleSchema
  users: type: [Object]
  'users.$._id': type: String
  'users.$.hasUnreadMessage': type: Boolean
  'users.$.lastSentDate': type: Date, optional: true
  expiresAt: type: Date
  expired: type: Boolean, optional: true
  lastMessageText: type: String, optional: true
  type:
    type: String
    allowedValues: ['yes']

# MARK - Instance Methods
Connections.helpers

  isExpired: ->
    @expired

  messages: ->
    Messages.find
      connectionId: @_id

  otherUserId: (thisUser) ->
    userIds = _.pluck @users, '_id'
    if _.contains(userIds, thisUser._id)
      return _.without(userIds, thisUser._id)[0]
    return null

  otherUser: (thisUser) ->
    recipientId = @otherUserId thisUser
    if recipientId?
      return Users.findOne recipientId
    return null

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
    lastSentDates = _.compact _.pluck(@users, 'lastSentDate')
    if lastSentDates.length == 2
      # update expiresAt if both users have said something
      # TODO: once the concept of "never expiring" gets implemented for ketchy,
      # remove this logic, since expireAt should never be bigger than t + 3 days.
      expiresAt = new Date(Math.max(@expiresAt, Connections.nextExpirationDate _.min(lastSentDates)))

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
