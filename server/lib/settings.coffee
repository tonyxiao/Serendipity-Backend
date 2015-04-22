_.extend Meteor.settings, process.env

Meteor.settings.SOFT_MIN_BUILD = Meteor.settings.SOFT_MIN_BUILD or process.env.SOFT_MIN_BUILD or 0
Meteor.settings.HARD_MIN_BUILD = Meteor.settings.HARD_MIN_BUILD or process.env.HARD_MIN_BUILD or 0

if typeof Meteor.settings.SOFT_MIN_BUILD == "string"
  Meteor.settings.SOFT_MIN_BUILD = parseInt(Meteor.settings.SOFT_MIN_BUILD)

if typeof Meteor.settings.HARD_MIN_BUILD == "string"
  Meteor.settings.HARD_MIN_BUILD = parseInt(Meteor.settings.HARD_MIN_BUILD)


Meteor.settings.PHOTO_COUNT_TO_DISPLAY = Meteor.settings.PHOTO_COUNT_TO_DISPLAY or process.env.PHOTO_COUNT_TO_DISPLAY or 3
if typeof Meteor.settings.PHOTO_COUNT_TO_DISPLAY == "string"
  Meteor.settings.PHOTO_COUNT_TO_DISPLAY = parseInt(Meteor.settings.PHOTO_COUNT_TO_DISPLAY)

Meteor.settings.NUM_ALLOWED_ACTIVE_GAMES = Meteor.settings.NUM_ALLOWED_ACTIVE_GAMES or process.env.NUM_ALLOWED_ACTIVE_GAMES or 1

if typeof Meteor.settings.NUM_ALLOWED_ACTIVE_GAMES == "string"
  Meteor.settings.NUM_ALLOWED_ACTIVE_GAMES = parseInt(Meteor.settings.NUM_ALLOWED_ACTIVE_GAMES)

Meteor.settings.CRAB_USER_ID = Meteor.settings.CRAB_USER_ID or process.env.CRAB_USER_ID or "crab"
Meteor.settings.CRAB_FIRST_NAME =  Meteor.settings.CRAB_FIRST_NAME or process.env.CRAB_FIRST_NAME or "Ketchy"
Meteor.settings.CRAB_LAST_NAME = Meteor.settings.CRAB_LAST_NAME or process.env.CRAB_LAST_NAME or ""

Meteor.settings.WARM_WELCOME_TEXT = Meteor.settings.WARM_WELCOME_TEXT or process.env.WARM_WELCOME_TEXT or "Ahoy, Sailor! I'm Ketchy, your personal assistant. I'm here to answer questions and navigate you through an ocean of dating options. Please text or talk to me any time you need anything. I'm happy to help!"
Meteor.settings.SEGMENT_WRITE_KEY = Meteor.settings.SEGMENT_WRITE_KEY or process.env.SEGMENT_WRITE_KEY

Meteor.settings.REFRESH_INTERVAL_MILLIS = Meteor.settings.REFRESH_INTERVAL_MILLIS or process.env.REFRESH_INTERVAL_MILLIS or 86400000 # 24 hours
Meteor.settings.CRAB_EXPIRATION_DATE_MILLIS = Meteor.settings.CRAB_EXPIRATION_DATE_MILLIS or process.env.CRAB_EXPIRATION_DATE_MILLIS or 5680281600000 # December 31, 2149