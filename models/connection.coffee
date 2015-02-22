
@Connections = new Mongo.Collection 'connections'
Connections.timestampable()

# MARK: - Schema Validation
Connections.attachSchema new SimpleSchema
  userIds: type: [String]
  type:
    type: String
    allowedValues: ['yes', 'maybe']

# MARK - Instance Methods
Connections.helpers
  messages: ->
    Messages.find
      connectionId: @_id

  # Relative to current user
  otherUser: (thisUser) ->
    if _.contains(@userIds, thisUser._id)
      recipientId = _.without(@userIds, thisUser._id)[0]
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
