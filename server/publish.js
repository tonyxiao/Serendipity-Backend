var bunyan = Meteor.npmRequire('bunyan');
var logger = bunyan.createLogger({ name : "publications" });

Meteor.publish("messages", function() {
  if (this.userId) {
    return myMessages(this.userId);
  }
})

Meteor.publish("currentUser", function() {
  if (this.userId) {
    return buildUser(Meteor.users.find(this.userId));
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
          var clientConnection = buildConnection(
              self.userId, connections.findOne({ _id : connectionId }));

          var recipientId = clientConnection.recipient;

          // keep track of who the connected user is
          connectedUsers[connectionId] = recipientId;

          self.added("connections", clientConnection._id, clientConnection);
          self.added("users",  recipientId, buildUser(Meteor.users.findOne(recipientId)));
        }
      },

      removed: function(connectionId) {
        if (!initializing) {
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
      var clientConnection = buildConnection(self.userId, connection);
      var recipientId = clientConnection.recipient;

      connectedUsers[connection._id] = recipientId;

      self.added("connections", connection._id, connection);
      self.added("users", recipientId, buildUser(Meteor.users.findOne(recipientId)));
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

          self.added("matches", matchId, buildMatch(match));
          self.added("users",
              match.matchedUserId, buildUser(Meteor.users.findOne(match.matchedUserId)));
        }
      },

      removed: function(matchId) {
        if (!initializing) {
          var matchedUserId = matchedUsers[matchId];
          self.removed("matches", matchId);
          self.removed("users", matchedUserId);

          delete matchedUsers[matchId];
        }
      }
    })

    initializing = false;
    var currentMatches = matches.find({ matcherId: self.userId }).fetch()

    currentMatches.forEach(function(match) {
      matchedUsers[match._id] = match.matchedUserId;
      self.added("matches", match._id, buildMatch(match));
      self.added("users", match.matchedUserId,
          buildUser(Meteor.users.findOne(match.matchedUserId)));
    })

    self.ready()

    this.onStop(function() {
      handle.stop();
    })
  }
})