Template.vetQueue.helpers
  usersToVet: ->
    usersCursor = Users.find { vetted: $nin: ["yes", "blocked"] },
      { sort: createdAt: 1, firstName: 1 }

Template.vetQueue.events
  'click .vet-user': ->
    if confirm('sure?')
      Meteor.call 'admin/user/unvet', @_id