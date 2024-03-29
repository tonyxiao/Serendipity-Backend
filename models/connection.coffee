logger = new KetchLogger 'connections'
@Connections = new Mongo.Collection 'connections'
Connections.attachBehaviour('timestampable')

# MARK: - Schema Validation
Connections.attachSchema new SimpleSchema
  users: type: [Object]
  'users.$._id': type: String
  'users.$.hasUnreadMessage': type: Boolean
  'users.$.lastSentDate': type: Date, optional: true
  'users.$.lastMessageIdSeen': type: String, optional: true
  'users.$.lastTimestampSeen': type: Date, optional: true
  'users.$.promptText': type: String, optional: true
  expiresAt: type: Date
  expired: type: Boolean, optional: true
  lastMessageText: type: String, optional: true
  type:
    type: String
    allowedValues: ['yes']

# MARK - Instance Methods
Connections.helpers

  _validateUserVetted: (connectionUser) ->
    user = Users.findOne connectionUser._id
    if !user? or !user.isVetted()
      error = new Meteor.Error(500, "Please ensure that #{user._id} is vetted before modifying connection #{@_id}")
      logger.error(error)
      throw error

  _validateUsersVetted: ->
    if @users.length != 2
      error = new Meteor.Error(500, "Connection #{@_id} has more than 2 users?")
      logger.error(error)
      throw error

    connectionUser1 = @users[0]
    connectionUser2 = @users[1]

    # Non-ketchy connections should consist of only vetted users.
    if connectionUser1._id != Meteor.settings.crabUserId and connectionUser2._id != Meteor.settings.crabUserId
      @_validateUserVetted connectionUser1
      @_validateUserVetted connectionUser2

  isExpired: ->
    return @expired

  messages: ->
    Messages.find({
      connectionId: @_id
    }, { sort:
      createdAt: 1
    })


  lastMessageBy: (userId) ->
    messagesBySender = Messages.find({
      connectionId: @_id
      senderId: userId
    }, { sort:
      createdAt: -1
    }).fetch()

    # TODO: should use limit here, but limit is undefined in minimongo?
    if messagesBySender.length > 0
      return messagesBySender[0]

    logger.info "Could not find lastMessageBy #{userId} in connection #{@_id}"
    return null

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

  markAsReadFor: (user) ->
    @setUserKeyValue user, 'hasUnreadMessage', false
    otherUser = @otherUser user
    # stores the last message seen my the current user (from the other user)
    lastMessageSeenByCurrentUser = @lastMessageBy otherUser._id
    if lastMessageSeenByCurrentUser?
      @setUserKeyValue user, 'lastMessageIdSeen', lastMessageSeenByCurrentUser._id
      @setUserKeyValue user, 'lastTimestampSeen', new Date

  setUserKeyValue: (user, key, value) ->
    # First modify in memory
    info = @getUserInfo user
    info[key]  = value
    # Then modify in db
    selector = _id: @_id, 'users._id': user._id
    modifier = {}
    modifier["users.$.#{key}"] = value

    @_validateUsersVetted()
    Connections.update selector, $set: modifier

  unsetUserKey: (user, key) ->
    # First modify in memory
    info = @getUserInfo user
    delete info[key]
    # Then modify in db
    selector = _id: @_id, 'users._id': user._id
    modifier = {}
    modifier["users.$.#{key}"] = ""

    @_validateUsersVetted()
    Connections.update selector, $unset: modifier

  messageWithoutPushNotification: (text, sender) ->
    # TODO: error handling if text is null
    recipient = @otherUser sender
    Messages.insert
      connectionId: @_id
      senderId: sender._id
      recipientId: recipient._id
      text: text

    @setUserKeyValue sender, 'lastSentDate', new Date
    @setUserKeyValue recipient, 'hasUnreadMessage', true

    # prevent the prompt text from being shown again for both users, since an actual
    # conversation will happen soon.
    @unsetUserKey recipient, 'promptText'
    @unsetUserKey sender, 'promptText'

    # Compute the next expiration date
    lastSentDates = _.compact _.pluck(@users, 'lastSentDate')
    if lastSentDates.length == 2
      # update expiresAt if both users have said something
      # TODO: once the concept of "never expiring" gets implemented for ketchy,
      # remove this logic, since expireAt should never be bigger than t + 3 days.
      expiresAt = new Date(Math.max(@expiresAt, Connections.nextExpirationDate _.min(lastSentDates)))

    # This is to ensure that the Ketchy connection will not expire for at least
    # 5 years from the year that this message is sent
    # crabUserId = Meteor.settings.crabUserId
    #if (sender._id == crabUserId || recipient._id == crabUserId) &&  !(expiresAt.getFullYear() > new Date().getFullYear() + 5)
    #  error = new Meteor.Error(500, "The Ketchy connection (#{@_id}) is about to expire ... within 5 years")
    #  logger.error(error)
    #  throw error

    @_validateUsersVetted()
    Connections.update @_id,
      $set:
        lastMessageText: text
        expiresAt: expiresAt

  createNewMessage: (text, sender) ->
    # TODO: What's the right way to do this here? @fang refactor?
    recipient = @otherUser sender
    @messageWithoutPushNotification(text, sender)
    recipient.sendNotification "#{sender.firstName}: #{text}"

    # Forward message to ketchy to ketchy channel in Slack
    # TODO: Abstract out logic for localhost into meteor settings itself
    if recipient.isCrab() && process.env.ROOT_URL.indexOf('localhost') < 0
      # TODO: How to correctly join urls without worrying about presence of '/'
      message = "<#{process.env.ROOT_URL}connections/#{@_id}|#{sender.firstName} #{sender.lastName}>: #{text}"
      new SlackService('#ketchy', ':crabby:').send(message)

  removeAllMessages: ->
    Messages.remove
      connectionId: @_id

  remove: ->
    Connections.remove @_id

  clientView: (refUser) ->
    view = _.clone this

    otherUser = @otherUser(refUser)

    view.otherUserId = otherUser._id
    view.hasUnreadMessage = @getUserInfo(refUser).hasUnreadMessage
    view.otherUserLastSeenMessageId = @getUserInfo(otherUser).lastMessageIdSeen
    view.otherUserLastSeenAt = @getUserInfo(otherUser).lastTimestampSeen
    view.promptText = @getUserInfo(refUser).promptText

    delete view.users
    return view

Connections.nextExpirationDate = (relativeDate) ->
  expiration = new Date relativeDate.getTime()
  expiration.setDate expiration.getDate() + 3 # 3 days from now
  return expiration
