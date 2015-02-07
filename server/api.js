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
   * Creates a message, and adds it to an existing connection, if one exists. If one does
   * not exist, it will be created.
   *
   * @param matchedUserId: string; the matched user's id.
   * @param videoUrl: string; the uploaded URL of the video.
   *
   * @return the id of the new connection.
   */
  sendMessage: function(matchedUserId, videoUrl) {
    return addOrModifyConnectionWithNewMessage(this.userId, matchedUserId, videoUrl);
  }
});