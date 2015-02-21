
@Connections = new Mongo.Collection 'connections'
Connections.timestampable()

# MARK: - Schema Validation
Connections.attachSchema new SimpleSchema
  userIds: type: [String]
  messageIds:
    type: [String]
    optional: true


# MARK - Instance Methods
Connections.helpers
  messages: ->
    Messages.find
      connectionId: @_id

  # Relative to current user
  otherUser: (thisUser) ->
    thisUser ?= Users.current()
    if _.contains(@userIds, thisUser._id)
      recipientId = _.without(@userIds, thisUser._id)[0]
      return Users.findOne recipientId

  createNewMessage: (text, sender) ->
    # TODO: error handling if text is null
    sender ?= Users.current()
    recipient = @otherUser(sender)
    messageId = Messages.insert
      senderId: sender._id,
      recipientId: recipient._id,
      isUnread: true

    Connections.update {_id: @_id},
      $push:
        messageIds: messageId
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
    delete view.messageIds
    return view


# TODO: Remove once outdated references are refactored
@connections = Connections
