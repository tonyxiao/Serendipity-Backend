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
    matches.remove({
      matcherId: this.userId
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
    var schools = ["Harvard", "Yale", "Princeton", "Columbia", "Cornell", "Dartmouth",
      "Penn"];

    var locations = [
      "San Francisco, CA",
      "Mountain View, CA",
      "Palo Alto, CA",
      "Menlo Park, CA",
      "Sausalito, CA",
      "San Mateo, CA",
      "Cupertino, CA",
      "Sunnyvale, CA",
      "Berkeley, CA"
    ];

    var jobs = ["Google", "Goldman Sachs", "Shell", "Boston Consulting Group",
      "Ben & Jerrys", "In N Out", "Facebook"];

    var users = JSON.parse(usersString);
    var userNames = [];
    users.results.forEach(function(user) {
      userNames.push(user.name);

      var school = schools[Math.floor(Math.random() * schools.length)];
      var location = locations[Math.floor(Math.random() * locations.length)];
      var job = jobs[Math.floor(Math.random() * jobs.length)];

      var photos = [];
      user.photos.forEach(function(photo) {
        photo.processedFiles.forEach(function(processedPhoto){
          if (processedPhoto.height == 640 && processedPhoto.width == 640) {
            photos.push(processedPhoto.url);
          }
        })
      });

      var serviceData = {
        id: user._id,
        email: user._id + "@gmail.com",
        password: user._id,
        birthday: user.birthday
      };

      var meteorId = Accounts.updateOrCreateUserFromExternalService("facebook",
          serviceData, {});

      Meteor.users.update({_id : meteorId.userId}, {
        $set: {
          "firstName" : user.name,
          "about" : user.bio,
          "education" : school,
          "createdAt" : new Date(),
          "age" : Math.floor((Math.random() * 10) + 20), // random 20 <= x <=30
          "location" : location,
          "work" : job,
          photos: photos
        }
      })
    });

    return userNames.join(",");
  }
});


