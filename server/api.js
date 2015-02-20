Meteor.methods({
    // TODO: make params be a dictionary, too hard to understand otherwise
  chooseYesNoMaybe: function(yesMatchId, noMatchId, maybeMatchId) {
      candidates.update(yesMatchId, {
          $set: { choice: 'yes' }
      });
      candidates.update(noMatchId, {
          $set: { choice: 'no' }
      });
      candidates.update(maybeMatchId, {
          $set: { choice: 'maybe' }
      });
      var yesMatch = candidates.findOne(yesMatchId);
      var noMatch = candidates.findOne(noMatchId);
      var maybeMatch = candidates.findOne(maybeMatchId);

    // TODO: Remove irrelevant matches (no's and not-matched) from candidateQueue subscription
      var result = {};
      [yesMatch, maybeMatch].forEach(function (candidate) {
          var inverseMatch = candidates.findOne({
              matcherId: candidate.matchedUserId,
              matchedUserId: candidate.matcherId,
              choice: candidate.choice
          });
          if (inverseMatch) {
              var connectionId = connections.insert({
                  users: [candidate.matchedUserId, candidate.matcherId],
                  messages: [],
                  dateUpdated : new Date(),
                  dateCreated: new Date(),
                  type: candidate.choice
              });
              result[candidate.choice] = connectionId;
          }
      });
      for (var i = 0; i < 3; i++) {
          newMatch(this.userId);
      }

      return result
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