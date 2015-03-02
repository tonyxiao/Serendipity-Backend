
Template._candidateList.events
  'click .remove-candidate': ->
    Meteor.call 'candidate/remove', @_id

  'click .create-inverse': ->
    Meteor.call 'candidate/createInverse', @_id

  'click .my-choice .say-yes': ->
    Meteor.call 'candidate/makeChoice', @_id, 'yes'

  'click .my-choice .say-no': ->
    Meteor.call 'candidate/makeChoice', @_id, 'no'

  'click .my-choice .say-maybe': ->
    Meteor.call 'candidate/makeChoice', @_id, 'maybe'

  'click .their-choice .say-yes': ->
    Meteor.call 'candidate/makeChoiceForInverse', @_id, 'yes'

  'click .their-choice .say-no': ->
    Meteor.call 'candidate/makeChoiceForInverse', @_id, 'no'

  'click .their-choice .say-maybe': ->
    Meteor.call 'candidate/makeChoiceForInverse', @_id, 'maybe'

Template.userCandidates.events
  'click .add-logged-in-user-to-queue': ->
    if confirm('sure?')
      Meteor.call 'candidate/new', @_id, Meteor.user()._id
      Meteor.call 'candidate/new', Meteor.user()._id, @_id
      # add 2 additional users to make sure that the currently logged in user will be able
      # to play a game
      Meteor.call 'user/populateCandidateQueue', @_id, 2
      Meteor.call 'user/populateCandidateQueue', Meteor.user()._id, 2

  'click .populate-queue': ->
    if confirm('sure?')
      Meteor.call 'user/populateCandidateQueue', @_id

  'click .clear-queue': ->
    if confirm('sure?')
      Meteor.call 'user/clearCandidateQueue', @_id

Template.userPreviousCandidates.events
  'click .clear-previous-candidates': ->
    if confirm("sure?")
      Meteor.call 'user/clearPreviousCandidates', @_id

