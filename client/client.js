var permissions = ['email', 'user_photos', 'user_birthday', 'user_education_history',
  'user_about_me', 'user_work_history'];

Template.body.helpers({
  photos: function() {
    if (Meteor.user()) {
      return Meteor.user().profile.photos;
    } else {
      return [];
    }
  }
});

Template.body.events({
  'click button': function(event) {
      Meteor.loginWithFacebook({ requestPermissions: permissions}, function (error) {
        if (error) {
          return console.log(error);
        }

        Meteor.call("loginWithFacebook", function(err, urls) {});
      });
  }
})
