_.extend Meteor.settings, process.env

Meteor.settings.PHOTO_COUNT_TO_DISPLAY = process.env.PHOTO_COUNT_TO_DISPLAY or 3