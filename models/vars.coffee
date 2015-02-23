# Needed to make connection filtering reactive
@CurrentDate = new ReactiveVar new Date
Meteor.setInterval ->
  CurrentDate.set new Date
, 1000
