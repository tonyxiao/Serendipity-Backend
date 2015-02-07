Meteor.methods({
  matchPass: function(matchedUserId) {
    // TODO(qimingfang): push matchedUserId into user's previous matches.

    Meteor.users.update({_id : this.userId}, {
      $pull: {
        "profile.matches": matchedUserId
      }
    });

    var match = nextMatch(Meteor.user(), matchedUserId);
    Meteor.users.update({_id : this.userId}, {
      $push : {
        "profile.matches" : match._id
      }
    })
  },

  /**
   * For clients to accept a match for the first time, and make a new connection.
   * @param matchedUserId: string; the matched user's id.
   * @param videoUrl: string; the uploaded URL of the video.
   *
   * @return the id of the new connection.
   */
  matchAccept: function(matchedUserId, videoUrl) {
    return newConnection(this.userId, matchedUserId, videoUrl);
  }
});