connections = new Mongo.Collection("connections");

var _newConnection = function(senderId, recipientId) {
  var connectionId = connections.insert({
    users: [senderId, recipientId],
    messages: [],
    created_on: new Date().getTime()
  })

  return connectionId;
}

var _appendMessageIdToConnection = function(connectionId, messageId) {
  return connections.update({ _id : connectionId}, {
    $push : {
      messages : messageId
    }
  })
}

/**
 * Adds a new message. If a connection exists, append to it. Otherwise, create a new
 * connection.
 *
 * @param senderId: string; the sender user's id
 * @param recipientId: string; the recipient user's id
 * @param videoUrl: string; the url of the first message
 */
addOrModifyConnectionWithNewMessage = function(senderId, recipientId, videoUrl) {
  var messageId = newMessage(senderId, recipientId, videoUrl);

  var connection = connections.findOne({
    users: {
      $in: [senderId, recipientId]
    }
  });

  if (connection == undefined) {
    var connectionId = _newConnection(senderId, recipientId);
  } else {
    var connectionId = connection._id;
  }

  _appendMessageIdToConnection(connectionId, messageId);

  return updateMessageWithConnectionId(messageId, connectionId);
}