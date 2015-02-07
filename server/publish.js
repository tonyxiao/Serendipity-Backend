var bunyan = Meteor.npmRequire('bunyan');
var logger = bunyan.createLogger({ name : "publications" });

Meteor.publish("messages", function() {
  if (this.userId) {
    return myMessages(this.userId);
  }
})

Meteor.publish("currentUser", function() {
  if (this.userId) {
    return Meteor.users.find({_id: this.userId});
  }
})

/**
 * Publishes topic called 'connectedUsers' which populates a client side collection called
 * 'connectedUsers' with {@code Meteor.user} instances for all of the current user's
 * connections.
 */
Meteor.publish("connections", function() {
  if (this.userId) {
    var self = this

    // a dictionary of connection_id to connected user
    var connectedUsers = {};

    var initializing = true;
    var handle = connections.find({
      users : {
        $in : [self.userId]
      }
    }).observeChanges({
      added: function(connectionId) {
        if (!initializing) {
          var connectedUserId = _getConnectedUserFromConnection(
              connectionId, self.userId);

          connectedUsers[connectionId] = connectedUserId;

          self.added("connections", connectionId, connections.findOne(connectionId));
          self.added("users", connectedUserId,
              Meteor.users.findOne({_id : connectedUserId}));
        }
      },

      removed: function(connectionId) {
        if (!initializing) {
          var connectedUserId = _getConnectedUserFromConnection(
              connectionId, self.userId);

          self.removed("connections", connectionId)
          self.removed("users", connectedUsers[connectionId]);

          delete connectedUsers[connectionId];
        }
      }
    })

    initializing = false;
    var currentUserConnections = connections.find({
      users : {
        $in : [self.userId]
      }
    }).fetch();

    currentUserConnections.forEach(function(connection) {
      var connectedUserId = _getConnectedUserFromConnection(connection._id, self.userId);
      connectedUsers[connection._id] = connectedUserId;
      self.added("connections", connection._id, connection)
      self.added("users", connectedUserId, Meteor.users.findOne(connectedUserId))
    })

    self.ready()

    this.onStop(function() {
      handle.stop();
    })
  }
})

/**
 * Publishes topic called 'matchedUsers' which populates a client side collection called
 * 'matchedUsers' with {@code Meteor.user} instances for all of the current user's
 * connections.
 */
Meteor.publish("matches", function() {
  if (this.userId) {
    var self = this

    // a dictionary of match_id to matched user
    var matchedUsers = {};

    var initializing = true;
    var handle = matches.find({
      matcherId: self.userId
    }).observeChanges({
      added: function(matchId) {
        if (!initializing) {
          var match = matches.findOne(matchId);
          matchedUsers[matchId] = match.matchedUserId;

          self.added("matches", matchId, match);
          self.added("users",
              match.matchedUserId, Meteor.users.findOne(match.matchedUserId));
        }
      },

      removed: function(matchId) {
        if (!initializing) {
          var matchedUserId = matchedUsers[matchId];
          self.removed("matches", matchId);
          self.removed("users", matchedUserId, Meteor.users.findOne(matchedUserId))

          delete matchedUsers[matchId];
        }
      }
    })

    initializing = false;
    var currentMatches = matches.find({ matcherId: self.userId }).fetch()

    currentMatches.forEach(function(match) {
      matchedUsers[match._id] = match.matchedUserId;
      self.added("matches", match._id, match);
      self.added("users", match.matchedUserId, Meteor.users.findOne(match.matchedUserId));
    })

    self.ready()

    this.onStop(function() {
      handle.stop();
    })
  }
})

var _getConnectedUserFromConnection = function(connectionId, currentUserId) {
  var connection = connections.findOne({ _id : connectionId });
  var connectedUserId = connection.users[0] == currentUserId
      ? connection.users[1] : connection.users[0];

  return connectedUserId;
}
