/**
 * @returns a function to generate a random user whose id is not equal to @id
 */
var _randomFromCollection = function(C) {
  return function (id, currentMatchedId) {
    // just 1 = current user for now. Will include previous matches in the future.
    var numUsersToExclude = 2;

    c = C.find({
      _id: {$nin : [id, currentMatchedId]}
    }).fetch();

    i = randomInRange(0, C.find().count() - numUsersToExclude - 1)
    return c[i]
  }
}

/**
 * @returns a match for the current user.
 */
nextMatch = function(currentUser, currentMatchId) {
  return _randomFromCollection(Meteor.users)(currentUser._id, currentMatchId);
}

nextMatches = function(currentUser, currentMatchId, numMatches) {
  toReturn = [];
  for (var i = 0; i < numMatches; i++) {
    toReturn.push(nextMatch(currentUser, currentMatchId)._id);
  }

  return toReturn;
}