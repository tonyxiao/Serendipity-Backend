describe 'Client user view', () ->
  describe 'profilePhotoUrl', () ->
    newPhoto = (url, order) ->
      active: true
      order: order
      url: url

    beforeEach () ->
      Users.remove({})

    it 'should have proper profile photo url', () ->
      userId = Users.insert
        firstName: 'test'
        photos: [newPhoto('http://test.jpg', 0), newPhoto('http://iamhappy.jpg', 1)]
      user = Users.findOne userId
      expect(user.profilePhotoUrl()).toEqual('http://test.jpg')

    it 'should be undefined if the user did not upload any photos', () ->
      userId = Users.insert
        firstName: 'test'
      user = Users.findOne userId
      expect(user.profilePhotoUrl()).toBeUndefined()