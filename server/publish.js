var bunyan = Meteor.npmRequire('bunyan');
var logger = bunyan.createLogger({ name : "publications" });

Meteor.publish("userData", function() {
  if (this.userId) {
    return Meteor.users.find({_id: this.userId});
  }
})

Meteor.publish("matches", function() {
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
            self.added("matches", matchId, Meteor.users.findOne({_id : matchId}));
          });

          // remove old matches from client users collection that are no longer relevant
          var oldMatches = matchedUsers.filter(function (e) {
            return matches.indexOf(e) < 0;
          });
          oldMatches.forEach(function(matchId) {
            self.removed("matches", matchId);
          })

          matchedUsers = matches;
        }
      }
    })

    initializing = false;
    var matches = Meteor.users.findOne({_id : self.userId}, {}).profile.matches;

    if (matches != undefined) {
      matches.forEach(function (matchId) {
        self.added("matches", matchId, Meteor.users.findOne({_id: matchId}));
      })

      matchedUsers = matches;
    }

    self.ready()

    this.onStop(function() {
      handle.stop();
    })
  }
})

Meteor.methods({
  matchPass: function(matchedUserId) {
    // TODO(qimingfang): push matchedUserId into user's previous matches.

    Meteor.users.update({_id : this.userId}, {
      $pull: {
        "profile.matches": matchedUserId
      }
    });

    var match = nextMatch(Meteor.user(), matchedUserId);
    Meteor.users.update({_id : this.userId}, {
      $push : {
        "profile.matches" : match._id
      }
    })
  }
});