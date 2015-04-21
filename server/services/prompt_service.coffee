
class @PromptService

  @prompts: ->
    return  [
      "Let's go for a nice walk along the beach?",
      "Where can I find the best sunset around here?",
      "Want to ketch up over a cup of coffee sometime?"
    ]

  @getPrompt: (promptIdToExclude) ->
    prompts = @prompts()

    if !promptIdToExclude?
      index = Math.floor(Math.random() * prompts.length)
      return index

    # cannot find a separate prompt if there is only 1 available prompt
    if prompts.length == 1
      return 0

    if promptIdToExclude < 0
      error = new Meteor.Error(500, "Invalid promptIdToExclude #{promptIdToExclude}");
      logger.error(error)
      throw error

    index = promptIdToExclude
    while index == promptIdToExclude
      index = Math.floor(Math.random() * prompts.length)

    return index
