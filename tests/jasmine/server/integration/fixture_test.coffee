
describe 'Fixtures', ->
  beforeEach ->
    Users.remove {}

  describe 'Tinder', ->

    it 'Imports then clears fake users', ->
      importUserCount = Tinder.importFakeUsers(10)
      expect(Users.find().count()).toEqual(importUserCount)

      Users.insert firstName: 'tester'
      expect(Users.find().count()).toEqual(importUserCount + 1)

      Tinder.clearFakeUsers()
      expect(Users.find().count()).toEqual(1)

  # TODO: Add a test to make sure tinder user id does not change in subscription
