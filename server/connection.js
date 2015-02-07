connections = new Mongo.Collection("connections");

/**
 * Adds a connection with an existing message
 *
 * @param senderId: string; the sender user's id
 * @param recipientId: string; the recipient user's id
 * @param videoUrl: string; the url of the first message
 */
newConnection = function(senderId, recipientId, videoUrl) {
  var messageId = newMessage(senderId, recipientId, videoUrl);

  var connectionId = connections.insert({
    users: [senderId, recipientId],
    messages: [messageId],
    created_on: new Date().getTime()
  })

  addConnection(messageId, connectionId);

  return connectionId;
}