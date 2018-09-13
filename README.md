# WebSAP
WebSAP is the **web session application protocol**. It allows multiple apps
to run simulatenously on the same server, each having a virtually infinite
number of concurrent sessions.

## Protocol
  - GET `/apps`: List supported apps
  - GET `/apps/[app]/new`: Create a new app of type `app`. Returns the `id` of the
  new session.
  - GET `/apps/[id]/state`: Gets the state of the session.
  - POST `/apps/[id]/message`: Posts a message to a session, invoking its app's
  `transform` method.

## Apps
Each app implementation needs three things:
  1. `name`: The name of the app.
  2. `initial_state`: The initial state of any new session for this app.
  3. `transform(state, action, options)`: A function which takes an existing
  state reference, an action string, and an options hash. `state` should be
  mutated based on `action` and `options`. Return `true` if everything was
  valid with `action` and `options`, or false otherwise.