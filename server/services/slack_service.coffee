class @SlackService
  constructor: (channel, emoji) ->
    @channel = channel
    @emoji = emoji

  send: (message) ->
    if @channel? and @emoji?
      webhook_url = Meteor.settings.slack.url
      payload =
        channel: @channel
        icon_emoji: @emoji
        username: Meteor.settings.env
        text: message
      Meteor.npmRequire('request').post(webhook_url).json(payload)