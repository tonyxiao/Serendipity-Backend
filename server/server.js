Meteor.startup(function () {
	Accounts.loginServiceConfiguration.remove({
	  service: "facebook"
	});
	Accounts.loginServiceConfiguration.insert({
	  service: "facebook",
	  appId: "788119904575103",
	  secret: "3414955c6ceb3b89fcd9d315bdb74869"
	});

	Meteor.methods({
		/**
		 * When given the FB token, fetches user photos to store on
		 * Azure, and saves user in DB
		 *
		 * @fbToken token the facebook authentication token
		 * @return the id of the user
		 */
		getPicturesFromFacebook: function(fbToken) {
			var graph = Meteor.npmRequire('fbgraph');
      if (Meteor.user().services.facebook.accessToken) {
        graph.setAccessToken(Meteor.user().services.facebook.accessToken);

        var fetchFromFacebook = Meteor.wrapAsync(graph.get);
        var photos = fetchFromFacebook('/me/photos').data

        return photos;
      } else {
      	throw new Meteor.Error(401,
      		'Error 401: Not found', 'Unauthorized');
      }
		}
	})
});
