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
      Accounts.callLoginMethod(
        { methodArguments: [

          { "fb-access": {
            accessToken: "CAALNMjGdKs0BAI1RdEnKnKgBVlLZBjmFWzrQyXVbyVt56ZCyZBH3jkr6LiYZARJRQnUHnmmkuT94MN9DnQlZAxyVVqiaNlJwaMZBvZA8Q7k8fqsrAXOv38eGPEaO0RUCKCH3eyFCAw1FTxR47C6rD5FQVlRQg8EAT48nGw9dJYxHE3Rrf7y47FGebDKvR9OZBvyHyto0l8RVRhboqZCeok7bp",
            expiresAt: 1427621876406,
            id: '10152550599801513',
            email: 'tonyx.ca@gmail.com',
             name: 'Tony Xiao',
             first_name: 'Tony',
             last_name: 'Xiao',
             link: 'https://www.facebook.com/app_scoped_user_id/10152550599801513/',
             gender: 'male',
             locale: 'en_US'
            }
          }
        ]
      });

     /*
      { requestPermissions: permissions}, function (error) {
        if (error) {
          return console.log(error);
        }

        Meteor.call("loginWithFacebook", function(err, urls) {
          console.log("done");
        });
      });
*/
  }
})
