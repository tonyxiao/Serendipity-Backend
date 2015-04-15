class @KetchLogger
  constructor: (source) ->
    if Meteor.isServer
      @logger = Meteor.npmRequire('bunyan').createLogger(name: source)

  error: (e) ->
    if @logger?
      @logger.error(e)

  info: (i) ->
    if @logger?
      @logger.info(i)