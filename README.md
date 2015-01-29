# S10 Backend

##APIs
This section documents the method signatures of the published methods of the S10 server.
#### Login
The S10 server expects a facebook based login. Clients are in charge of obtaining their own access tokens from facebook. Upon getting a token, they should call the `login` method, passing in as arguments a dictionary like:

```
{ methodArguments: 
  [{ "fb-access": {
    accessToken: (user's FB access token: string),
    expiresAt: (time of token expiration: millis since 1970),
    id: (user's facebook id: string),
    email: (user's FB email: string),
    name: (user's FB name: String),
    first_name: (user's FB first name: String),
    last_name: (user's FB last name: String),
    link: (A link to the user's profile: URL string),
    gender: (user's FB gender. String: male | female),
    locale: (user's FB locale, i.e. 'en_US')
   }
  }]
}
```

Clients should get back a login response, in the form of

```
{ type: 'facebook', userId: 'RFdNWPobvtnJJvD8c' /* the meteor' user's id */ }
```
