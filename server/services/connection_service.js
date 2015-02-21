/**
 * Created by Tony on 2/20/15.
 */

var _newConnection = function(senderId, recipientId) {
    var connectionId = connections.insert({
        users: [senderId, recipientId],
        messages: [], // OPTIONAL
        dateUpdated : new Date(),
        dateCreated: new Date()
    })

    return connectionId;
}

var _appendMessageIdToConnection = function(connectionId, messageId) {
    return connections.update({ _id : connectionId}, {
        $push : {
            messages : messageId
        },
        $set : {
            dateUpdated : new Date()
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
addOrModifyConnectionWithNewMessage = function(
    senderId, recipientId, thumbnailUrl, videoUrl) {
    var messageId = newMessage(senderId, recipientId, thumbnailUrl, videoUrl);

    var connection = connections.findOne({
        $and: [
            { users : { $in : [senderId] }},
            { users : { $in : [recipientId] }}
        ]
    });

    if (connection == undefined) {
        var connectionId = _newConnection(senderId, recipientId);
    } else {
        var connectionId = connection._id;
    }

    _appendMessageIdToConnection(connectionId, messageId);

    return updateMessageWithConnectionId(messageId, connectionId);
}

/**
 * Builds a client representation of the connection.
 *
 * @param userId: string;
 * @param connection; a {@code Meteor.connection}
 *
 * @return an (updated) {@code Meteor.connection}.
 */
buildConnection = function(userId, connection) {
    var recipient = _getConnectedUserFromConnection(connection, userId);
    //delete connection["users"]
    delete connection["messages"]

    connection.recipient = recipient;

    return connection;
}


var _getConnectedUserFromConnection = function(connection, currentUserId) {
    var connectedUserId = connection.users[0] == currentUserId
        ? connection.users[1] : connection.users[0];

    return connectedUserId;
}
