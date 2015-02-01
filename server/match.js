/**
 * @returns a function to generate a random user whose id is not equal to @id
 */
var _randomFromCollection = function(C) {
  return function (id) {
    // just 1 = current user for now. Will include previous matches in the future.
    var numUsersToExclude = 1;

    c = C.find({
      _id: {$ne : id}
    }).fetch();

    i = randomInRange(0, C.find().count() - numUsersToExclude - 1)
    return c[i]
  }
}

/**
 * @returns a match for the current user.
 */
var _nextMatch = function(currentUser) {
  return _randomFromCollection(Meteor.users)(currentUser._id);
}

/**
 * Updates the @paramCurrentUser with the next match
 */
updateNextMatch = function(currentUser) {
  var match = _nextMatch(currentUser);
  Meteor.users.update({_id: currentUser._id}, {
    $set: {
      "currentMatch": match
    }
  })
}