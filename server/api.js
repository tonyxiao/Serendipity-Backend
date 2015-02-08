Meteor.methods({
  matchPass: function(matchId) {
    // TODO(qimingfang): push matchedUserId into user's previous matches.
    passMatch(matchId, this.userId);
    newMatch(this.userId);
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
  sendMessage: function(matchedUserId, thumbnailUrl, videoUrl) {
    return addOrModifyConnectionWithNewMessage(
        this.userId, matchedUserId, thumbnailUrl, videoUrl);
  }
});