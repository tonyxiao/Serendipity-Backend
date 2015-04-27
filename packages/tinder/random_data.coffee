@RandomData =
  school: ->
    _.sample [
      'Harvard'
      'Yale'
      'Princeton'
      'Columbia'
      'Cornell'
      'Dartmouth'
      'Penn'
    ]

  location: ->
    _.sample [
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

  job: ->
    _.sample [
      'Google'
      'Goldman Sachs'
      'Shell'
      'Boston Consulting Group'
      'Ben & Jerrys'
      'In N Out'
      'Facebook'
    ]

  age: ->
    _.sample [19..35]

  height: ->
    _.sample [150...210] # in cm

  lastName: ->
    _.sample ["Crab", "Fang", "Xiao", "Ketch", "Krivoruchko"]

  gender: ->
    _.sample ['male', 'female']
