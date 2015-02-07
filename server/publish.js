var bunyan = Meteor.npmRequire('bunyan');
var logger = bunyan.createLogger({ name : "publications" });

Meteor.publish("connections", function() {
  if (this.userId) {
    return connections.find({
      users: {
        $in: [this.userId]
      }
    })
  }
})

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
Meteor.publish("connectedUsers", function() {
  if (this.userId) {
    var self = this
    var connectedUsers = [];

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

          self.added("connectedUsers", connectedUserId,
              Meteor.users.findOne({_id : connectedUserId}));
        }
      },

      removed: function(connectionId) {
        if (!initializing) {
          var connectedUserId = _getConnectedUserFromConnection(
              connectionId, self.userId);

          self.removed("connectedUsers", connectedUserId,
              Meteor.users.findOne({_id: connectedUserId}));
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
      self.added("connectedUsers", connectedUserId, Meteor.users.findOne(connectedUserId))
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
Meteor.publish("matchedUsers", function() {
  if (this.userId) {
    var self = this
    var matchedUsers = [];

    var initializing = true;
    var handle = Meteor.users.find({_id : self.userId}).observeChanges({
      changed: function(id) {
        if (!initializing) {
          var matches = Meteor.users.findOne({_id : self.userId}, {}).profile.matches;

          if (matches == undefined) {
            logger.error("could not publish matches because user %s " +
              "does not have matches field set", self.userId);
            return;
          }

          // add new matches to client users collection that were not cached
          var newMatches = matches.filter(function (e) {
            return matchedUsers.indexOf(e) < 0;
          });
          newMatches.forEach(function(matchId) {
            self.added("matchedUsers", matchId, Meteor.users.findOne({_id : matchId}));
          });

          // remove old matches from client users collection that are no longer relevant
          var oldMatches = matchedUsers.filter(function (e) {
            return matches.indexOf(e) < 0;
          });
          oldMatches.forEach(function(matchId) {
            self.removed("matchedUsers", matchId);
          })

          matchedUsers = matches;
        }
      }
    })

    initializing = false;
    var matches = Meteor.users.findOne({_id : self.userId}, {}).profile.matches;

    if (matches != undefined) {
      matches.forEach(function (matchId) {
        self.added("matchedUsers", matchId, Meteor.users.findOne({_id: matchId}));
      })

      matchedUsers = matches;
    }

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
