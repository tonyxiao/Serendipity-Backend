Package.onUse(function(api) {
  api.versionsFrom('1.1.0.2');
  api.use(['coffeescript', 'underscore'], 'server');
  api.use(['models']);
  api.addFiles('random_data.coffee');
  api.addFiles('tinder.coffee');
  api.addFiles([
    "girls_1", "girls_2", "girls_3", "girls_4", "girls_5", "girls_6",
    "guys_1", "guys_2", "guys_3", "guys_4", "guys_5", "guys_6", "guys_7"
  ].map(function(f) { return 'fixtures/' + f + '.json'; }), 'server', { isAsset: true });
  api.export('Tinder');
});

Package.onTest(function(api) {
  api.use(['coffeescript', 'underscore']);
  api.use('tinytest');
  api.use('tinder');
  api.addFiles('tinder-tests.coffee', 'server');
});
