Template.body.helpers({
	photos: function() {
		return Session.get("photos") || "";
	}
});

Template.body.events({
	'click button': function(event) {
			Meteor.loginWithFacebook({
				requestPermissions: ['email', 'user_photos']}, function (error) {
					if (error) {
						return console.log(error);
					}

					Meteor.call("getPicturesFromFacebook", function(err, result) {
						Session.set('photos', result);
					});
			});
	}
})