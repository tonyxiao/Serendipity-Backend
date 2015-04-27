
Tinytest.add 'Validate fixture json', (test) ->
  _(fixtureNames).each (name) ->
    data = getFixture name
    test.isNotNull data

Tinytest.add 'Parse fixtures', (test) ->
  data = getFixture fixtureNames[0]
  users = parseUserList data
  test.isNotNull users

Tinytest.add 'Import fake users', (test) ->
  console.log process.cwd()
  Tinder.importFakeUsers()
  test.fail 'Not implemented'

Tinytest.add 'Clear fake users', (test) ->
  Tinder.clearFakeUsers()
  test.fail 'Not implemented'