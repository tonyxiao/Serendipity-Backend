// Copied from https://github.com/dburles/meteor-collection-helpers/blob/master/collection-helpers.js
// Unfortunately directly depending on meteor-collections-helpers from package.js does not seem to work
// See possible explanation in https://github.com/rclai/meteor-collection-extensions

Mongo.Collection.prototype.helpers = function(helpers) {
  var self = this;

  if (self._transform && ! self._helpers)
    throw new Meteor.Error("Can't apply helpers to '" +
        self._name + "' a transform function already exists!");

  if (! self._helpers) {
    self._helpers = function Document(doc) { return _.extend(this, doc); };
    self._transform = function(doc) {
      return new self._helpers(doc);
    };
  }

  _.each(helpers, function(helper, key) {
    self._helpers.prototype[key] = helper;
  });
};