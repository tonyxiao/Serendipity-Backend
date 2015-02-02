Meteor.publish("userData", function() {
  if (this.userId) {
    return Meteor.users.find({_id: this.userId});
  } else {
    this.ready();
  }
})

Meteor.methods({
  nextMatch: function() {
    updateNextMatch(Meteor.user());
  }
});