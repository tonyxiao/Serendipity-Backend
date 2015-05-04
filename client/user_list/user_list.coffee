
Template.userList.helpers
  users: ->
    users = Users.find({
      'services.tinder': {
        $exists: false
      }
    }).fetch()
    okUsers = []
    Users.find().fetch().forEach (user) ->
      if user.candidateQueue().fetch().length >= Candidates.NUM_CANDIDATES_PER_GAME
        okUsers.push(user)
    return okUsers

  crab: ->
    crabUser = Settings.findOne("crabUserId")
    if crabUser?
      return Users.findOne crabUser.value

  # TODO: refactor this and {@code users} to share code.
  usersRunningOutOfVettedCandidates: ->
    runningOutOfMatches = []
    Users.find(
      $exists: false
    ).fetch().forEach (user) ->
      if user.candidateQueue().fetch().length < Candidates.NUM_CANDIDATES_PER_GAME
        runningOutOfMatches.push(user)
    return runningOutOfMatches

Template.userList.events
  'keyup #search': ->
    searchText = $('#search').val().toLowerCase()
    $(".user-list li a span").each () ->
      name = $(this).text().toLowerCase()

      listItem = $(this).parent().parent()
      if (name.indexOf(searchText) == -1)
        listItem.hide()
      else
        listItem.show()



