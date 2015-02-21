var bunyan = Meteor.npmRequire('bunyan');

var logger = bunyan.createLogger({ name : "debug" });

// TODO(qimingfang): remove this. it is used for debugging.
function getRandomInRange(from, to, fixed) {
  return (Math.random() * (to - from) + from).toFixed(fixed) * 1;
  // .toFixed() returns string, so ' * 1' is a trick to convert to number
}

// TODO(qimingfang): remove this. it is used for debugging.
Meteor.publish('allUsers', function() {
  return Meteor.users.find();
});

Meteor.publish('allMatches', function() {
  return candidates.find();
});

Meteor.users.allow({
  insert: function(){
    return true;
  },
  update: function(){
    return true;
  },
  remove: function(){
    return true;
  }
});
// RPC methods clients can call.
Meteor.methods({
  chooseForMatchedUser: function(matchedUserId, choice) {
    var currentUserId = Meteor.user()._id;
    var inverseMatch = candidates.update({
      matcherId: matchedUserId,
      matchedUserId: currentUserId
    }, {
      $set: {
        choice: choice,
        dateMatched: new Date()
      }
    }, {
      upsert: true
    });
    console.log('Chose ' + choice + ' for ' + matchedUserId);
    return inverseMatch
  },
  matchMe: function() {
    var currentUser = Meteor.user();

    // a newly registered user will have an empty previous matches array.
    if (currentUser.previousMatches == undefined) {
      Meteor.users.update({_id: currentUser._id}, {
        $set: {
          previousMatches : []
        }
      })
    }

    // new user has no matches yet.
    var currentMatches = getCurrentMatches(currentUser._id);
    if (currentMatches.length == 0) {
      for (var i = 0; i < 5; i++) {
        newMatch(currentUser._id);
      }
    }
  },

  // TODO(qimingfang): remove this method. it is for debugging.
  clearAllUsers : function() {
    Meteor.users.remove({});
  },

  // TODO(qimingfang): remove this method. it is for debugging.
  getEnv : function() {
    return process.env;
  },

  // TODO(qimingfang): remove this method. it is for debugging.
  clearCurrentUser: function() {
    Meteor.users.remove({_id : Meteor.user()._id})
  },

  clearCurrentUserMessages: function() {
    messages.remove({
      $or: [
        { senderId: Meteor.user()._id },
        { recipientId: Meteor.user()._id }
      ]
    });
  },

  clearCurrentUserConnections: function() {
    connections.remove({
      users: {
        $in: [this.userId]
      }
    });
  },

  clearCurrentUserMatches: function() {
    candidates.remove({
      matcherId: this.userId
    })

    Meteor.users.update(this.userId, {
      $set : {
        previousMatches : []
      }
    })
  },

  validConnections: function() {
    console.log(connections.find({
      users: {
        $in: [this.userId]
      }
    }).fetch());
  },

  findUser: function(id) {
    return Meteor.users.find(id).fetch()
  },

  // TODO(qimingfang): remove this method. it is for debugging.
  addUsers: function(usersString) {
      var data = JSON.parse(usersString);
      return FixtureService.importFromTinder(data);
  }
});


