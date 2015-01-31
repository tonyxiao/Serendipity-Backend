Meteor.methods({
  nextMatch: function() {
    updateNextMatch(Meteor.user());
  }
});