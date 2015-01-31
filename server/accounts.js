var graph = Meteor.npmRequire('fbgraph');

Meteor.startup(function () {

  // Login handler for FB
  Accounts.registerLoginHandler("fb-access", function (serviceData) {
    var loginRequest = serviceData["fb-access"];
    var accessToken = loginRequest.access_token;

    var myInfo = Meteor.http.call("GET",
        "https://graph.facebook.com/me?access_token=" + accessToken).data;
    myInfo.accessToken = accessToken;
    myInfo.expireAt = loginRequest.expire_at;

    var meteorid = Accounts.updateOrCreateUserFromExternalService("facebook", myInfo,
        {profile: {first_name: myInfo.first_name}});

    var currentUser = Meteor.users.findOne(meteorid.userId);

    graph.setAccessToken(currentUser.services.facebook.accessToken);
    var fbGetFn = Meteor.wrapAsync(graph.get);

    // update user photos if this is they don't have facebook.
    if (currentUser.photos == undefined) {
      var urls = getUserPhotos(fbGetFn, currentUser);
      Meteor.users.update({_id: currentUser._id}, {
        $set: {
          "current_match": null,
          "previous_matches": [],
          "connections": [],
          "profile.photos": urls
        }
      });
    }

    return meteorid;
  });
});
