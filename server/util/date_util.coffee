time = Meteor.npmRequire('time')

class @DateUtil
  @DEFAULT_TIME_ZONE = "America/Los_Angeles"

  # returns @Date at 3:33pm tomorrow
  @nextNotificationTimeMillis: (now) ->
    nowInDefautTimezone = new time.Date(now.getTime())
    nowInDefautTimezone.setTimezone(@DEFAULT_TIME_ZONE)
    nowInDefautTimezone.setHours(24 + 15, 33, 33, 0)
    return new Date(nowInDefautTimezone.getTime())