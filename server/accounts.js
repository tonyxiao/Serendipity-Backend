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

    var meteorId = Accounts.updateOrCreateUserFromExternalService("facebook", myInfo,
        {profile: {first_name: myInfo.first_name}});

    var currentUser = Meteor.users.findOne(meteorId.userId);

    graph.setAccessToken(currentUser.services.facebook.accessToken);
    var fbGetFn = Meteor.wrapAsync(graph.get);

    // update user photos if this is they don't have facebook.
    if (currentUser.photos == undefined) {
      var urls = getUserPhotos(fbGetFn, currentUser);
      Meteor.users.update({_id: currentUser._id}, {
        $set: {
          "profile.photos": urls
        }
      });
    }

    // new user has no matches yet.
    var currentMatches = getCurrentMatches(currentUser._id);
    if (currentMatches.length == 0) {
      for (var i = 0; i < 5; i++) {
        newMatch(currentUser._id);
      }
    }
    return meteorId;
  });
});
