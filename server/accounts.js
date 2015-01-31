var graph = Meteor.npmRequire('fbgraph');

Meteor.startup(function () {

  // Login handler for FB
  Accounts.registerLoginHandler("fb-access", function (serviceData) {
    var meteorid = Accounts.updateOrCreateUserFromExternalService("facebook",
        serviceData["fb-access"],
        {profile: {name: serviceData["fb-access"].name}});

    var currentUser = Meteor.users.findOne(meteorid.userId);

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

    return meteorid;
  });
});
