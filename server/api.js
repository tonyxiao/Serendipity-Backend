Meteor.methods({

  /**
   * The current user in session passes on the user with id {@code matchId}. Requests a
   * new match for the current user.
   *
   * @param matchId the id of the user to pass
   */
  matchPass: function(matchId) {
    passMatch(matchId, this.userId);
    newMatch(this.userId);
  },

    // TODO: make params be a dictionary, too hard to understand otherwise
  chooseYesNoMaybe: function(yesMatchId, noMatchId, maybeMatchId) {
      matches.update(yesMatchId, {
          $set: { choice: 'yes' }
      });
      matches.update(noMatchId, {
          $set: { choice: 'no' }
      });
      matches.update(maybeMatchId, {
          $set: { choice: 'maybe' }
      });
      var yesMatch = matches.findOne(yesMatchId);
      var noMatch = matches.findOne(noMatchId);
      var maybeMatch = matches.findOne(maybeMatchId);

    // TODO: Remove irrelevant matches (no's and not-matched) from matches subscription


      var result = {};
      [yesMatch, maybeMatch].forEach(function (match) {
          var inverseMatch = matches.findOne({
              matcherId: match.matchedUserId,
              matchedUserId: match.matcherId,
              choice: match.choice
          });
          if (inverseMatch) {
              var connectionId = connections.insert({
                  users: [match.matchedUserId, match.matcherId],
                  messages: [],
                  dateUpdated : new Date(),
                  dateCreated: new Date(),
                  type: match.choice
              });
              result[match.choice] = connectionId;
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