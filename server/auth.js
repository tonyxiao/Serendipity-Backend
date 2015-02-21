var bunyan = Meteor.npmRequire('bunyan');
  graph = Meteor.npmRequire('fbgraph');

var logger = bunyan.createLogger({ name : "accounts" });

Meteor.startup(function () {
  // Login handler for FB
  Accounts.registerLoginHandler("fb-access", function (serviceData) {
    var loginRequest = serviceData["fb-access"];
    var accessToken = loginRequest.accessToken;

    var myInfo = Meteor.http.call("GET",
        "https://graph.facebook.com/me?access_token=" + accessToken).data;
    myInfo.accessToken = accessToken;
    myInfo.expireAt = loginRequest.expire_at;

    var meteorId = Accounts.updateOrCreateUserFromExternalService("facebook", myInfo, {});

    Meteor.users.update({_id : meteorId.userId}, {
      $set: {
        firstName : myInfo.first_name,
        about : myInfo.first_name,
        education : "Harvard", // TODO
        age : 23, // TODO
        location : "mountain view, ca",
        work : "google",
        createdAt : new Date()
      }
    })

    var currentUser = Meteor.users.findOne(meteorId.userId);

    graph.setAccessToken(currentUser.services.facebook.accessToken);
    var fbGetFn = Meteor.wrapAsync(graph.get);

    // update user photos if this is they don't have facebook.
    if (currentUser.photos == undefined) {
      var urls = getUserPhotos(fbGetFn, currentUser);
      Meteor.users.update({_id: currentUser._id}, {
        $set: {
          photos: urls
        }
      });
    }

    // a newly registered user will have an empty previous matches array.
    if (currentUser.previousMatches == undefined) {
      Meteor.users.update({_id: currentUser._id}, {
        $set: {
          previousMatches : []
        }
      })
    }

    //// new user has no matches yet.
    //var currentMatches = getCurrentMatches(currentUser._id);
    //if (currentMatches.length == 0) {
    //  for (var i = 0; i < 12; i++) {
    //    newMatch(currentUser._id);
    //  }
    //}
    return meteorId;
  });
});

/**
 * Returns info about the user, given the userId. Fields that are not relevant will be
 * destroyed.
 *
 * @param userId
 */
buildUser = function(user) {
  delete user.services
  return user;
}