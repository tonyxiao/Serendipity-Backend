var async = Meteor.npmRequire('async'),
  bunyan = Meteor.npmRequire('bunyan'),
  fs = Npm.require('fs'),
  gm = Meteor.npmRequire('gm').subClass({ imageMagick: true }),
  graph = Meteor.npmRequire('fbgraph'),
  Future = Npm.require('fibers/future')
  path = Npm.require('path')
  request = Meteor.npmRequire('request'),
  util = Npm.require('util');

var logger = bunyan.createLogger({ name : "s10-server" });

Meteor.startup(function () {
  Accounts.loginServiceConfiguration.remove({
  service: "facebook"
});
Accounts.loginServiceConfiguration.insert({
  service: "facebook",
  appId: process.env.FB_APPID || '',
  secret: process.env.FB_SECRET || '',
});

// can update their own profile
Meteor.users.allow({
  update: function(userId, doc){
    return doc._id === userId;
  }
});

var client = Meteor.npmRequire('pkgcloud').storage.createClient({
  provider: 'azure',
  storageAccount: process.env.AZURE_ACCOUNTID || '',
  storageAccessKey: process.env.AZURE_ACCESSKEY || ''
});

/**
 * Fetches user photos from facebook and pipes them to Azure.
 * 
 * @param _fbGetFn function that issues a GET against FB graph. 
 * @return a String[] of Azure photo URLs.
 */
function getUserPhotos(_fbGetFn) {
  var photos = _fbGetFn('/me/photos').data

  var futures = _.map(photos, function(photo) {
    var future = new Future();
    var onComplete = future.resolver();
    
    var writeStream = client.upload({
      container: process.env.AZURE_CONTAINER || 's10-dev',
      remote: util.format("%s/%s", Meteor.user()._id, photo.id)
    });

    writeStream.on('success', function(file) {
      var url = util.format("%s%s.%s/%s/%s", client.protocol,
        client.config.storageAccount,
        client.serversUrl,
        file.container,
        file.name);
      onComplete(null, url);
    });

    writeStream.on('error', function(err) {
      logger.error(err);
      onComplete(err);
    })

    request(photo.source).pipe(writeStream);
    return future;
  }); 

  Future.wait(futures);
  
  var azureUrls = [];
  futures.forEach(function(future) {
    azureUrls.push(future.get());
  });

  return azureUrls;
}

/**
 * Populates fields from the '/me' graph api call.
 */
function updateBasicFbInfo(_fbGetFn) {
  var profile = _fbGetFn('/me');

  Meteor.users.update({ _id: Meteor.userId() }, { $set: {
    "profile.first_name": profile.first_name,
    "profile.last_name": profile.last_name,
    "profile.gender": profile.gender,
    "profile.work": profile.work,
    "profile.education":  profile.education
  }});
}

Meteor.methods({
 /**
  * When given the FB token, fetches user photos to store on
  * Azure, and saves user in DB
  */
  loginWithFacebook: function() {
    if (Meteor.user().services.facebook.accessToken) {
      graph.setAccessToken(Meteor.user().services.facebook.accessToken);
      var fbGetFn = Meteor.wrapAsync(graph.get);
      
      // update user photos if this is they don't have facebook.
      if (Meteor.user().photos == undefined) {
        var urls = getUserPhotos(fbGetFn);
        Meteor.users.update ( { _id: Meteor.userId() }, { $set: {
          "profile.photos": urls
        }});
      }
     
      // update basic info of the user on every login. 
      updateBasicFbInfo(fbGetFn);
    } else {
      throw new Meteor.Error(401,
        'Error 401: Not found', 'Unauthorized');
      }
    }
  })
});


