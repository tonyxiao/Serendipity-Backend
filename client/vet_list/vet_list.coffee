Template.vetQueue.helpers
  usersToVet: ->
    usersCursor = Users.find { vetted: $ne: true },
      { sort: createdAt: 1, firstName: 1 }