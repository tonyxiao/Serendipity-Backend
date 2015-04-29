time = Meteor.npmRequire('time')

describe 'Date util', () ->
  describe 'nextNotificationTimeMillis', () ->
    it 'should return 3:33pm tomorrow', () ->
      # apr 28, 23:45:45 PDT
      now = new Date 1430289945000
      newDate = new time.Date(DateUtil.nextNotificationTimeMillis now)
      newDate.setTimezone("America/Los_Angeles")

      expect(newDate.getHours()).toBe(15)
      expect(newDate.getMinutes()).toBe(33)
      expect(newDate.getSeconds()).toBe(33)
      expect(newDate.getDate()).toBe(29)
      expect(newDate.getMonth()).toBe(3)
      expect(newDate.getFullYear()).toBe(2015)
