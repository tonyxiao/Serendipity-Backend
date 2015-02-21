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
  }
});