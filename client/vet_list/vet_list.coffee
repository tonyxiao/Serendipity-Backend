Template.vetQueue.helpers
  snoozedUsers: ->
    return Users.find { vetted: "snoozed" },
      { sort: createdAt: 1, firstName: 1 }

  blockedUsers: ->
    return Users.find { vetted: "blocked" },
      { sort: createdAt: 1, firstName: 1 }