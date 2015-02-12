matches = new Mongo.Collection("matches");

/**
 * Returns a list of {@cod match} objects for the user with id @param currentUserId.
 */
getCurrentMatches = function(currentUserid) {
  return matches.find({ matcherId : currentUserid }).fetch()
}

newMatch= function(currentUserId) {
  var matchedUser = nextMatch(currentUserId);
  if (matchedUser != undefined) {
    matches.insert({
      matcherId: currentUserId,
      matchedUserId: matchedUser._id,
      dateMatched: new Date()
    })

    // push currently matched user to the current user's previous matches.
    Meteor.users.update(currentUserId, {
      $push : {
        previousMatches : matchedUser._id
      }
    })

    console.log("added " + matchedUser._id + " to matches");
  }
}

/**
 * Called when a user with {@code currentUserId} wants to pass on a user with
 * {@code matchId}.
 */
passMatch = function(matchId, currentUserid) {
  var match = matches.findOne(matchId);
  if (match == undefined || match.matcherId != currentUserid) {
    console.log("User " + currentUserId + " cannot remove match " + matchId);
    return;
  }

  return matches.remove(matchId);
}

/**
 * @returns a match {@link Meteor.user} for the current user.
 */
nextMatch = function(currentUserId) {
  var currentUser = Meteor.users.findOne(currentUserId);

  // a user should not match to a previous match
  var ineligibleUserIds = currentUser.previousMatches;

  // a user cannot match to themselves.
  ineligibleUserIds.push(currentUserId);

  return _randomFromCollection(Meteor.users)(ineligibleUserIds);
}

/**
 * Builds a client representation of the match.
 *
 * @param match a {@code Meteor.match}
 * @returns an updated {@code Meteor.match}
 */
buildMatch = function(match) {
  delete match.matcherId;

  return match;
}

/**
 * @returns a function to generate a random user whose id is not equal to @id
 */
var _randomFromCollection = function(C) {
  /**
   * @param ineligibleUserIds array of userIds this user cannot be matched with
   */
  return function (ineligibleUserIds) {
    var numUsersToExclude = ineligibleUserIds.length;

    c = C.find({
      _id: {$nin : ineligibleUserIds}
    }).fetch();

    i = randomInRange(0, C.find().count() - numUsersToExclude - 1)
    return c[i]
  }
}
