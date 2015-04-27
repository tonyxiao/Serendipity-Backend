
Tinytest.add 'Parse fixtures', (test) ->
  _(fixtureNames).each (name) ->
    data = getFixture name
    users = parseUserList data
    test.isNotNull users

Tinytest.add 'Import then clear fake users', (test) ->
  Users.remove {}
  Tinder.importFakeUsers()
  test.equal Users.find().count(), 143

  Users.insert firstName: 'Tester'
  test.equal Users.find().count(), 144

  Tinder.clearFakeUsers()
  test.equal Users.find().count(), 1

