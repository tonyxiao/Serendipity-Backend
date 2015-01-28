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
  Accounts.registerLoginHandler("fb-ios", function(serviceData) {
    console.log("in login handler");
    return Accounts.updateOrCreateUserFromExternalService("facebook",
      serviceData["fb-ios"], { profile: { name: 'Tony Xiao' } });
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

  var DEFAULT_PHOTO_COUNT = process.env.DEFAULT_PHOTO_COUNT || 4;
  var DEFAULT_SIZE = process.env.DEFAULT_SIZE || 640;

  /**
   * Fetches user photos from facebook and pipes them to Azure.
   * 
   * @param _fbGetFn function that issues a GET against FB graph. 
   * @return a String[] of Azure photo URLs.
   */
  function getUserPhotos(_fbGetFn) {
    var photos = _fbGetFn('/me/photos').data.slice(0, DEFAULT_PHOTO_COUNT);

    var futures = _.map(photos, function(photo) {
      var future = new Future();
      var onComplete = future.resolver();

      // out of all images bigger than DEFAULT_SIZE x DEFAULT_SIZE, pick the one that has the
      // least number of pixels (to improve download).
      var imageToCrop = null;
      var _totalPixels = 0;
      photo.images.forEach(function(image) {
        if (image.height >= DEFAULT_SIZE && image.width >= DEFAULT_SIZE &&
          image.height * image.width > _totalPixels) {
          imageToCrop = image; 
          _totalPixels = image.height * image.width;
        }
      });
     
      if (imageToCrop == null) {
        logger.error("could not find any images bigger than " + DEFAULT_SIZE + "x" +
          DEFAULT_SIZE + " for result: " + photo);
        onComplete(null, null); 
      } else {
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
       
        var startX = (imageToCrop.width - DEFAULT_SIZE) / 2;
        var startY = (imageToCrop.height - DEFAULT_SIZE) / 2;
        
        // get the facebook photo and then crop it.
        gm(request.get(imageToCrop.source))
          .crop(DEFAULT_SIZE, DEFAULT_SIZE, startX, startY)
          .stream()
          .pipe(writeStream);
      }

      return future;
    }); 

    Future.wait(futures);
    
    var azureUrls = [];
    futures.forEach(function(future) {
      var result = future.get();
      
      // in the case that facebook did not have a large enough image, result will be null
      if (result != null) {
        azureUrls.push(result);
      }
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
    loginWithFacebook: function(serviceName, serviceData, options) {
      if (Meteor.user().services.facebook.accessToken) {
        graph.setAccessToken(Meteor.user().services.facebook.accessToken);
        var fbGetFn = Meteor.wrapAsync(graph.get);
        
        // update user photos if this is they don't have facebook.
        //if (Meteor.user().photos == undefined) {
          var urls = getUserPhotos(fbGetFn);
          Meteor.users.update ( { _id: Meteor.userId() }, { $set: {
            "profile.photos": urls
          }});
        //}
       
        // update basic info of the user on every login. 
        updateBasicFbInfo(fbGetFn);
      } else {
        throw new Meteor.Error(401,
          'Error 401: Not found', 'Unauthorized');
      }
    }
  });
});


