Template.vetQueue.helpers
  snoozedUsers: ->
    return Users.find { 'metadata.vetted': "snoozed" },
      { sort: createdAt: 1, firstName: 1 }

  blockedUsers: ->
    return Users.find { 'metadata.vetted': "blocked" },
      { sort: createdAt: 1, firstName: 1 }