Package.onUse(function(api) {
  api.versionsFrom('1.1.0.2');
  api.use('coffeescript', 'server');
  api.addFiles('settings.coffee', 'server');
  api.addFiles('settings.yml', 'server', {isAsset: true});
});

Npm.depends({
  'yamljs': '0.2.1'
});
