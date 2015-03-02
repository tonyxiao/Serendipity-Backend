Template.footer.events
  'click .update-fb-access-token': ->
    if confirm('sure?')
      Meteor.logout()
