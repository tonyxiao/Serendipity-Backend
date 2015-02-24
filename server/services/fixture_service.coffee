
class @FixtureService

  # See sample_tinder_recs.json
  @importFromTinder: (data) ->
    schools = [
      'Harvard'
      'Yale'
      'Princeton'
      'Columbia'
      'Cornell'
      'Dartmouth'
      'Penn'
    ]
    locations = [
      'San Francisco, CA'
      'Mountain View, CA'
      'Palo Alto, CA'
      'Menlo Park, CA'
      'Sausalito, CA'
      'San Mateo, CA'
      'Cupertino, CA'
      'Sunnyvale, CA'
      'Berkeley, CA'
    ]
    jobs = [
      'Google'
      'Goldman Sachs'
      'Shell'
      'Boston Consulting Group'
      'Ben & Jerrys'
      'In N Out'
      'Facebook'
    ]

    userNames = []
    console.log 'Will add users', data.results
    for user in data.results
      userNames.push user.name
      console.log 'Will add user with name ' + user.name
      school = schools[Math.floor(Math.random() * schools.length)]
      location = locations[Math.floor(Math.random() * locations.length)]
      job = jobs[Math.floor(Math.random() * jobs.length)]
      photos = []
      user.photos.forEach (photo) ->
        photo.processedFiles.forEach (processedPhoto) ->
          if processedPhoto.height == 640 and processedPhoto.width == 640
            photos.push processedPhoto.url
      serviceData =
        id: user._id
        email: user._id + '@gmail.com'
        password: user._id
        birthday: user.birthday
      # TODO: Don't hack on top of facebook here, rather unnecessary
      meteorId = Accounts.updateOrCreateUserFromExternalService('facebook', serviceData, {})
      Users.update meteorId.userId,
        $set:
          firstName: user.name
          about: user.bio
          education: school
          createdAt: new Date
          age: Math.floor(Math.random() * 10 + 20)
          location: location
          work: job
          photoUrls: photos

    return userNames.join ','