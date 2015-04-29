class @DateUtil
  # returns @Date at 3:33pm tomorrow
  @nextNotificationTimeMillis: (now) ->
    newDate = new Date(now.getTime())
    newDate.setHours(24 + 15, 33, 33, 0)
    return newDate