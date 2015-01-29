var permissions = ['email', 'user_photos', 'user_birthday', 'user_education_history',
  'user_about_me', 'user_work_history'];

var accessToken = null;

(function(d, debug){
     var js, id = 'facebook-jssdk', ref = d.getElementsByTagName('script')[0];
     if (d.getElementById(id)) {return;}
     js = d.createElement('script'); js.id = id; js.async = true;
     js.src = "//connect.facebook.net/en_US/all" + (debug ? "/debug" : "") + ".js";
     ref.parentNode.insertBefore(js, ref);
   }(document, /*debug*/ false));

// get the access token at start of page.
window.fbAsyncInit = function() {
  // init the FB JS SDK
  FB.init({
    appId      : '788565417863885', // App ID from the App Dashboard
    channelUrl : '//localhost:3000/channel.html', // Channel File for x-domain communication for localhost debug
    // channelUrl : '//yoururl.com/channel.html', // Channel File for x-domain communication
    status     : true, // check the login status upon init?
    cookie     : true, // set sessions cookies to allow your server to access the session?
    xfbml      : true  // parse XFBML tags on this page?
  });

  FB.getLoginStatus(checkLoginStatus);

  function call_facebook_login(response){
    FB.api('/me', function(fb_user){
      fb_user.accessToken = response.authResponse.accessToken;
      fb_user.expireAt = new Date() + 1000 * response.expiresIn

      console.log(fb_user);

      Accounts.callLoginMethod({
        methodArguments: [{ "fb-access": fb_user }]
      });
    });
  }

  function checkLoginStatus(response) {
    if(response && response.status == 'connected') {
      console.log('User is authorized');
      call_facebook_login(response);
    } else {
      // Login the user
      FB.login(function(response) {
        if (response.authResponse) {
          call_facebook_login(response);
        } else {
          console.log('User cancelled login or did not fully authorize.');
        }
      }, {scope: permissions.join()});
    }
  }
}

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
    Meteor.call('clearAllUsers', function(err, res) {
      if (err) {
        console.log(err);
      }

      console.log("cleared all usrs");
    })
  }
})
