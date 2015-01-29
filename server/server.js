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

  var client = Meteor.npmRequire('pkgcloud').storage.createClient({
    provider: 'azure',
    storageAccount: process.env.AZURE_ACCOUNTID || '',
    storageAccessKey: process.env.AZURE_ACCESSKEY || ''
  });

  var PHOTO_COUNT = process.env.DEFAULT_PHOTO_COUNT || 4;
  var IMAGE_SIZE = process.env.DEFAULT_IMAGE_SIZE || 640;

  /**
   * Fetches user photos from facebook and pipes them to Azure.
   *
   * @param _fbGetFn function that issues a GET against FB graph.
   * @return a String[] of Azure photo URLs.
   */
  function getUserPhotos(_fbGetFn, currentUser) {
    var photos = _fbGetFn('/me/photos').data;

    // gather the right number of photos.
    var imagesToDownload = [];
    for (var i = 0; i < photos.length && i < PHOTO_COUNT; i++) {
      var photo = photos[i];

      // out of all images bigger than IMAGE_SIZE x IMAGE_SIZE, pick the
      // one that has the least number of pixels (to improve download).
      var imageToCrop = null;
      var _totalPixels = 0;
      photo.images.forEach(function(image) {
        if (image.height >= IMAGE_SIZE && image.width >= IMAGE_SIZE &&
          image.height * image.width > _totalPixels) {
          imageToCrop = image;
          _totalPixels = image.height * image.width;
        }
      });

      if (imageToCrop != null) {
        imageToCrop.id = photo.id;
        imagesToDownload.push(imageToCrop);
      }
    }

    var futures = _.map(imagesToDownload, function(image) {
      var future = new Future();
      var onComplete = future.resolver();

      var writeStream = client.upload({
        container: process.env.AZURE_CONTAINER || 's10-dev',
        remote: util.format("%s/%s", currentUser._id, image.id)
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

      var startX = (image.width - IMAGE_SIZE) / 2;
      var startY = (image.height - IMAGE_SIZE) / 2;

      // get the facebook photo and then crop it.
      gm(request.get(image.source))
        .crop(IMAGE_SIZE, IMAGE_SIZE, startX, startY)
        .stream()
        .pipe(writeStream);

      return future;
    });

    Future.wait(futures);

    var azureUrls = [];
    futures.forEach(function(future) {
      var result = future.get();

      // in the case that facebook did not have a large enough image,
      // result will be null
      if (result != null) {
        azureUrls.push(result);
      }
    });

    return azureUrls;
  }

  // Login handler for FB
  Accounts.registerLoginHandler("fb-access", function(serviceData) {
    var meteorid = Accounts.updateOrCreateUserFromExternalService("facebook",
      serviceData["fb-access"],
      { profile: { name: serviceData["fb-access"].name } });

    var currentUser = Meteor.users.findOne(meteorid.userId);

    graph.setAccessToken(currentUser.services.facebook.accessToken);
    var fbGetFn = Meteor.wrapAsync(graph.get);

    // update user photos if this is they don't have facebook.
    if (currentUser.photos == undefined) {
      var urls = getUserPhotos(fbGetFn, currentUser);
      Meteor.users.update ( { _id: currentUser._id }, { $set: {
        "profile.photos": urls
      }});
    }

    return meteorid;
  });

  // RPC methods clients can call.
  Meteor.methods({
    // TODO(qimingfang): remove this method. it is for debugging.
    clearAllUsers : function() {
      Meteor.users.remove({});
    },

    // TODO(qimingfang): remove this method. it is for debugging.
    getEnv : function() {
      return process.env;
    }
  });
});


