messages = new Mongo.Collection("messages");

/**
 * Inserts a new message into the messages collections.
 * @param senderId: string; the id of the message sender
 * @param recipientId: string; the id of the message recipient
 * @param videoUrl: string; the url to the uploaded video
 *
 * @return the messageId
 */
newMessage = function(senderId, recipientId, videoUrl) {
  return messages.insert({
    senderId: senderId,
    recipientId: recipientId,
    videoUrl: videoUrl,
    timestamp: new Date()
  })
}

/**
 * Adds a new connection to the message
 * @param messageId: string; the id of the message.
 * @param connectionId: string; the id of the connection
 *
 * @returns the messageId
 */
updateMessageWithConnectionId = function(messageId, connectionId) {
  return messages.update({ _id : messageId}, {
    $set : {
      "connectionId" : connectionId
    }
  })
}

/**
 * Returns the messages that are part of connections that userid is part of
 * @param userId: string; the id of the user we want to look for messages.
 * @returns {Mongo.Cursor} for the return set of messages.
 */
myMessages = function(userId) {
  return messages.find({
    $and: [
      { connectionId: { $exists: true }},
      { $or: [
        { senderId: userId },
        { recipientId: userId }
      ]}
    ]
  })
}
