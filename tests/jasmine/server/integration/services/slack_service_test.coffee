# Mock of npm 'request'
class FakeRequest
  constructor: () ->
    @url = null
    @json = null
  post: (url) ->
    self = this
    @url = url
    return {
      json: (json) ->
        self.json = json
    }

describe 'Api Methods', () ->
  it 'should have the expected payload', () ->
    fakeRequest = new FakeRequest()

    spyOn(Meteor, 'npmRequire').and.returnValue(fakeRequest)

    service = new SlackService('#channel', ':crabby:')
    service.send('test')

    expect(fakeRequest.url).toEqual(Meteor.settings.slack.url)
    expect(fakeRequest.json.channel).toEqual('#channel')
    expect(fakeRequest.json.icon_emoji).toEqual(':crabby:')
    expect(fakeRequest.json.message).toEqual('test')