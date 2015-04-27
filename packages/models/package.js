Package.onUse(function(api) {
  api.versionsFrom('1.1.0.2');
  api.use([
    'meteor-platform', // Do we need the whole platform?
    'accounts-base',
    'coffeescript',
    'underscore',
    'aldeed:collection2',
    'matb33:collection-hooks',
    'zimme:collection-timestampable'
    // 'dburles:collection-helpers', // BUGBUG: This doesn't work, copying source to lib
  ]);
  api.addFiles([
    'lib/collection-helpers.js',
    'lib/logger.coffee',
    'candidate.coffee',
    'connection.coffee',
    'device.coffee',
    'message.coffee',
    'user.coffee'
  ]);
  //api.export(['Users', 'Connections', 'Candidates', 'Devices', 'Messages', 'KetchLogger']);
});

Package.onTest(function(api) {
  api.use(['coffeescript', 'underscore']);
  api.use('tinytest');
  api.use('models');
  api.addFiles('model-tests.coffee', 'server');
});

Npm.depends({
  'bunyan': '1.3.3'
});