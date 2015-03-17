_.extend Meteor.settings, process.env

Meteor.settings.PHOTO_COUNT_TO_DISPLAY = process.env.PHOTO_COUNT_TO_DISPLAY or 3
Meteor.settings.NUM_ALLOWED_ACTIVE_GAMES = process.env.NUM_ALLOWED_ACTIVE_GAMES or 1
