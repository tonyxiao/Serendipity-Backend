ServerSession = (function () {
  'use strict';

  var Collection = new Mongo.Collection('server-session');

  var checkForKey = function (key) {
    if (typeof key === 'undefined') {
      throw new Error('Please provide a key!');
    }
  };
  var getSessionValue = function (obj, key) {
    return obj && obj.values && obj.values[key];
  };
  var condition = function () {
    return true;
  };

  Collection.deny({
    'insert': function () {
      return true;
    },
    'update' : function () {
      return true;
    },
    'remove': function () {
      return true;
    }
  });

  // public client and server api
  var api = {
    'get': function (key, connectionId) {
      var sessionObj = Meteor.isServer ?
          Meteor.call('server-session/get', connectionId) : Collection.findOne();

      return getSessionValue(sessionObj, key);
    },
    'equals': function (key, expected, identical) {
      var sessionObj = Meteor.isServer ?
          Meteor.call('server-session/get') : Collection.findOne();

      var value = getSessionValue(sessionObj, key);

      if (_.isObject(value) && _.isObject(expected)) {
        return _(value).isEqual(expected);
      }

      if (identical == false) {
        return expected == value;
      }

      return expected === value;
    }
  };

  if (Meteor.isClient) {
    Meteor.subscribe('server-session');
  }

  if (Meteor.isServer) {
    Meteor.startup(function () {
      if (Collection.findOne()) {
        Collection.remove({}); // clear out all stale sessions
      }
    });

    Meteor.onConnection(function (connection) {
      var clientID = connection.id;

      if (!Collection.findOne({ 'clientID': clientID })) {
        Collection.insert({ 'clientID': clientID, 'values': {} });
      }

      connection.onClose(function () {
        Collection.remove({ 'clientID': clientID });
      });
    });

    Meteor.publish('server-session', function () {
      return Collection.find({ 'clientID': this.connection.id });
    });

    Meteor.methods({
      'server-session/get': function (connectionId) {
        if(connectionId == undefined) {
          connectionId = this.connection.id
        }
        return Collection.findOne({ 'clientID': connectionId });

      },
      'server-session/set': function (key, value) {
        if (this.connection) {
          checkForKey(key);

          if (!condition(key, value))
            throw new Meteor.Error('Failed condition validation.');

          var updateObj = {};
          updateObj['values.' + key] = value;

          Collection.update({ 'clientID': this.connection.id }, { $set: updateObj });
        }
      }
    });

    // server-only api
    _.extend(api, {
      'set': function (key, value) {
        Meteor.call('server-session/set', key, value);
      },
      'setCondition': function (newCondition) {
        condition = newCondition;
      }
    });
  }

  return api;
})();