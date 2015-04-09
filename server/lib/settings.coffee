_.extend Meteor.settings, process.env

Meteor.settings.SOFT_MIN_BUILD = Meteor.settings.SOFT_MIN_BUILD or process.env.SOFT_MIN_BUILD or 0
Meteor.settings.HARD_MIN_BUILD = Meteor.settings.HARD_MIN_BUILD or process.env.HARD_MIN_BUILD or 0
Meteor.settings.PHOTO_COUNT_TO_DISPLAY = Meteor.settings.PHOTO_COUNT_TO_DISPLAY or process.env.PHOTO_COUNT_TO_DISPLAY or 3
Meteor.settings.NUM_ALLOWED_ACTIVE_GAMES = Meteor.settings.NUM_ALLOWED_ACTIVE_GAMES or process.env.NUM_ALLOWED_ACTIVE_GAMES or 1
Meteor.settings.CRAB_USER_ID = Meteor.settings.CRAB_USER_ID or process.env.CRAB_USER_ID or "crab"
Meteor.settings.REFRESH_INTERVAL_MILLIS = Meteor.settings.REFRESH_INTERVAL_MILLIS or process.env.REFRESH_INTERVAL_MILLIS or 86400000 # 24 hours
Meteor.settings.CRAB_EXPIRATION_DATE_MILLIS = Meteor.settings.CRAB_EXPIRATION_DATE_MILLIS or process.env.CRAB_EXPIRATION_DATE_MILLIS or 5680281600000 # December 31, 2149