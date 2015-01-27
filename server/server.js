var async = Meteor.npmRequire('async'),
  bunyan = Meteor.npmRequire('bunyan'),
  fs = Npm.require('fs'),
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

var client = Meteor.npmRequire('pkgcloud').storage.createClient({
  provider: 'azure',
  storageAccount: process.env.AZURE_ACCOUNTID || '',
  storageAccessKey: process.env.AZURE_ACCESSKEY || ''
});

Meteor.methods({
  /**
  * When given the FB token, fetches user photos to store on
  * Azure, and saves user in DB
  */
  getPicturesFromFacebook: function() {
    if (Meteor.user().services.facebook.accessToken) {
      graph.setAccessToken(Meteor.user().services.facebook.accessToken);

      var fetchFromFacebook = Meteor.wrapAsync(graph.get);
      var photos = fetchFromFacebook('/me/photos').data

      var future = new Future();
      async.map(photos, function(photo, callback) {
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
          callback(null, url);
        });

        writeStream.on('error', function(err) {
          logger.error(err);
          callback(err);
        })

        request(photo.source).pipe(writeStream);
      }, function(err, results) {
        if (err) {
          logger.error(err);
          throw new Meteor.Error( 500,
            'There was an error processing your request' );
        }

        future.return(results);
      });

      return future.wait();
    } else {
      throw new Meteor.Error(401,
        'Error 401: Not found', 'Unauthorized');
      }
    }
  })
});
