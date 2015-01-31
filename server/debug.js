var bunyan = Meteor.npmRequire('bunyan');

var logger = bunyan.createLogger({ name : "s10-server" });

// TODO(qimingfang): remove this. it is used for debugging.
function getRandomInRange(from, to, fixed) {
  return (Math.random() * (to - from) + from).toFixed(fixed) * 1;
  // .toFixed() returns string, so ' * 1' is a trick to convert to number
}

// TODO(qimingfang): remove this. it is used for debugging.
Meteor.publish('allUsers', function() {
  return Meteor.users.find();
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
  addUsers: function(usersString) {
    var schools = ["Harvard", "Yale", "Princeton", "Columbia", "Cornell", "Dartmouth",
      "Penn"];
    var jobs = ["Google", "Goldman Sachs", "Shell", "Boston Consulting Group",
      "Ben & Jerrys", "In N Out", "Facebook"];

    var school = schools[Math.floor(Math.random() * 7)];
    var job = jobs[Math.floor(Math.random()) * 7];

    var longitude = getRandomInRange(-180, 180, 3);
    var latitude = getRandomInRange(-90, 90, 3);

    var users = JSON.parse(usersString);
    var userNames = [];
    users.results.forEach(function(user) {
      userNames.push(user.name);

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
        birthday: user.birthday,
        location: {
          longitude: longitude,
          latitude: latitude
        }};

      var profile = {
        profile: {
          first_name: user.name,
          last_name: "Fang",
          about: user.bio,
          photos: photos,
          education: school,
          work: job
        }
      };

      Accounts.updateOrCreateUserFromExternalService("facebook",
          serviceData, profile);
    });

    return userNames.join(",");
  }
});


