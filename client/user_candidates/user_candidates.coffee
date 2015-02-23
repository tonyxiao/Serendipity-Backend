
Template.userCandidates.events
  'click .populate-queue': ->
    if confirm('sure?')
      Meteor.call 'user/populateCandidateQueue', @_id

  'click .clear-queue': ->
    if confirm('sure?')
      Meteor.call 'user/clearCandidateQueue', @_id

Template.userCandidateList.events
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
