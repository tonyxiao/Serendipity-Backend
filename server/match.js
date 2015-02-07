matches = new Mongo.Collection("matches");

/**
 * Returns a list of {@cod match} objects for the user with id @param currentUserId.
 */
getCurrentMatches = function(currentUserid) {
  return matches.find({ matcherId : currentUserid }).fetch()
}

newMatch= function(currentUserId) {
  var matchedUser = nextMatch(currentUserId, 0 /* userId that doesn't exist */);
  if (matchedUser != undefined) {
    console.log("added " + matchedUser._id + " to matches");
    matches.insert({
      matcherId: currentUserId,
      matchedUserId: matchedUser._id,
      dateMatched: new Date().getTime()
    })
  }
}

passMatch = function(currentUserId, previousMatchUserId) {
  console.log("Passing " + previousMatchUserId);
  matches.remove({
    matcherId: currentUserId,
    matchedUserId: previousMatchUserId
  })
}

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
 * @returns a match {@link Meteor.user} for the current user.
 */
nextMatch = function(currentUser, currentMatchId) {
  return _randomFromCollection(Meteor.users)(currentUser._id, currentMatchId);
}

nextMatches = function(currentUser, currentMatchId, numMatches) {
  toReturn = [];
  for (var i = 0; i < numMatches; i++) {
    var match = nextMatch(currentUser, currentMatchId);

    if (match != undefined) {
      toReturn.push(match._id);
    }
  }

  return toReturn;
}