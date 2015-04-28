# Ketch Server [![Circle CI](https://circleci.com/gh/Ketchteam/ketch-server.svg?style=svg&circle-token=ee6ecf08305b88ec6c8a075ba2cbbde38873a04d)](https://circleci.com/gh/Ketchteam/ketch-server)

For local development, `.env` file isn't required, just do
```
ENV=local gulp settings --cwd .scripts/
meteor --settings settings.json
```

To mirror the environment of say the dev server, do
```
heroku config:pull --app ketch-dev
source .env # This will set the ENV used by gulp settings step
gulp settings --cwd .scripts/
meteor --settings settings.json
```

That's it, then go to `http://localhost:3000` to see the result and start development

Pro Tip: 

Use `/import` endpoint and json files in `fixtures` to create some filler users to play with.
