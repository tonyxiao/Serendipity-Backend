
Meteor.subscribe("currentUser");
Meteor.subscribe("connections");
Meteor.subscribe("messages");
Meteor.subscribe("candidates");
Meteor.subscribe("allMatches");

// when you navigate to "/two" automatically render the template named "Two".

var permissions = ['email', 'user_photos', 'user_birthday', 'user_education_history',
  'user_about_me', 'user_work_history'];

var accessToken = null;

(function(d, debug){
     var js, id = 'facebook-jssdk', ref = d.getElementsByTagName('script')[0];
     if (d.getElementById(id)) {return;}
     js = d.createElement('script'); js.id = id; js.async = true;
     js.src = "//connect.facebook.net/en_US/all" + (debug ? "/debug" : "") + ".js";
     ref.parentNode.insertBefore(js, ref);
   }(document, /*debug*/ false));

// get the access token at start of page.
window.fbAsyncInit = function() {
  Meteor.call('getEnv', function(err, env) {
    // init the FB JS SDK
    FB.init({
      appId      : env.FB_APPID, // App ID from the App Dashboard
      channelUrl : env.ROOT_URL + '/channel.html', // Channel File for x-domain communication for localhost debug
      // channelUrl : '//yoururl.com/channel.html', // Channel File for x-domain communication
      status     : true, // check the login status upon init?
      cookie     : true, // set sessions cookies to allow your server to access the session?
      xfbml      : true  // parse XFBML tags on this page?
    });

    FB.getLoginStatus(checkLoginStatus);
  });

  function call_facebook_login(response){
    loginRequest = {
      accessToken: response.authResponse.accessToken,
      expiresAt: new Date() + 1000 * response.expiresIn
    }

    Accounts.callLoginMethod({
      methodArguments: [{ "fb-access": loginRequest }]
    });
  }

  function checkLoginStatus(response) {
    if(response && response.status == 'connected') {
      console.log('User is authorized');
      call_facebook_login(response);
    } else {
      // Login the user
      FB.login(function(response) {
        if (response.authResponse) {
          call_facebook_login(response);
        } else {
          console.log('User cancelled login or did not fully authorize.');
        }
      }, {scope: permissions.join()});
    }
  }
}

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
    var matchedUserId = $(event.target).parent().data('userid');
    Meteor.call('chooseForMatchedUser', matchedUserId, 'yes', function(err, res) {
      if (err) {
        console.log(err);
      } else {
        console.log("made user " + matchedUserId + " choose yes");
      }
    });

  },

  'click .nomatch': function(event) {
    var matchedUserId = $(event.target).parent().data('userid');
    Meteor.call('chooseForMatchedUser', matchedUserId, 'no', function(err, res) {
      if (err) {
        console.log(err);
      } else {
        console.log("made user " + matchedUserId + " choose no");
      }
    });
  },

  'click .maybematch': function(event) {
    var matchedUserId = $(event.target).parent().data('userid');
    Meteor.call('chooseForMatchedUser', matchedUserId, 'maybe', function(err, res) {
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