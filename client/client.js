

// when you navigate to "/two" automatically render the template named "Two".

loginWithFacebookAccess();

Template.home.events({
  'click #testUser': function(event) {
    Accounts.createUser({
      username: "username",
      email: "email@gmail.com",
      password: "password",
      profile: {}
    }, function(error, res) {
      Meteor.call("matchMe");
    })
  },

  'click #deleteUser': function(event) {
    if (confirm('Sure?')) {
      Meteor.call('clearAllUsers', function(err, res) {
        if (err) {
          console.log(err);
        }

        console.log("cleared all users");
      })
    }
  },
  'click #deleteCurrentUser': function(event) {
    if (confirm('Sure?')) {
      Meteor.call('clearCurrentUser', function(err, res) {
        if (err) {
          console.log(err);
        }

        console.log("cleared current user");
      })
    }
  },

  'click #deleteCurrentUserMessages': function(event) {
    if(confirm('Sure?')) {
      Meteor.call('clearCurrentUserMessages', function(err, res) {
        if (err) {
          console.log(err);
        }

        console.log("cleared current user messages");
      })
    }
  },
  'click #populateCandidateQueue': function (event) {
      if (confirm('sure?')) {
          Meteor.call('populateCandidateQueue', Meteor.userId());
      }
  },

  'click #deleteCurrentUserConnections': function(event) {
    if (confirm('Sure?')) {
      Meteor.call('clearCurrentUserConnections', function(err, res) {
        if (err) {
          console.log(err);
        }

        console.log("cleared current user connections");
      })
    }
  },

  'click #clearCurrentUserMatches': function(event) {
    if (confirm('Sure?')) {
      Meteor.call('clearCurrentUserMatches', function(err, res) {
        if (err) {
          console.log(err);
        }

        console.log("cleared current user matches");
      })
    }
  },

  'click .yesmatch': function(event) {
    var matchedUserId = $(event.target).parent().data('candidateid');
    Meteor.call('forceInverseCandidateChoice', matchedUserId, 'yes', function(err, res) {
      if (err) {
        console.log(err);
      } else {
        console.log("made user " + matchedUserId + " choose yes");
      }
    });

  },

  'click .nomatch': function(event) {
    var matchedUserId = $(event.target).parent().data('candidateid');
    Meteor.call('forceInverseCandidateChoice', matchedUserId, 'no', function(err, res) {
      if (err) {
        console.log(err);
      } else {
        console.log("made user " + matchedUserId + " choose no");
      }
    });
  },

  'click .maybematch': function(event) {
    var matchedUserId = $(event.target).parent().data('candidateid');
    Meteor.call('forceInverseCandidateChoice', matchedUserId, 'maybe', function(err, res) {
      if (err) {
        console.log(err);
      } else {
        console.log("made user " + matchedUserId + " choose maybe");
      }
    });
  }
});

Template.home.helpers({
  matches: getCurrentMatchedUser

});

Template.matched.helpers({
  matches: getCurrentMatchedUser
});

Template.photos.helpers({
  photos: function() {
    if (Meteor.user()) {
      return Meteor.user().photos;
    } else {
      return [];
    }
  }
});

Template.add.helpers({
  users: function() {
    var allUsers = Meteor.users.find().fetch();
    allUsers.forEach(function(user) {
      if (user.photos.length > 0) {
        user.photos = [user.photos[0]];
      }
    });
    return allUsers;
  }
})

Template.add.events({
  'click button': function(event) {
    var users = document.getElementById("newUsers").value;
    var usersJson = JSON.stringify(eval("(" + users + ")"));
    Meteor.call('addUsers', usersJson, function(err, res) {
      if (err) {
        console.log(err);
      }

      console.log("added users: " + res);
    })
  }
})

function getCurrentMatches() {
  if (Meteor.user()) {
      return Users.current().candidateQueue().fetch()
  }
  return null;
}
window.getCurrentMatches = getCurrentMatches;

function getCurrentMatchedUser() {
  if (Meteor.user()) {
    var currentMatches = getCurrentMatches();

    if (currentMatches != null) {
      var users = [];
      currentMatches.forEach(function(match) {
        var user = Meteor.users.findOne(match.matchedUserId);
        user.profilePhoto = user.photos[0];
        var inverseMatch = candidates.findOne({
          matcherId: match.matchedUserId,
          matchedUserId: match.matcherId
        });
        if (inverseMatch != null) {
          user.theirChoice = inverseMatch.choice;
        } else {
          user.theirChoice = "tbd";
        }
        users.push(user);

      });

      return users
    }
  }

  return null;
}
window.getCurrentMatchedUser = getCurrentMatchedUser