require 'sinatra'
require 'json'
require 'uuid'
require 'securerandom'
require_relative 'apps/chat.rb'
require_relative 'apps/tictactoe.rb'

# App providers need this stuff:
#   name: The name of the app
#   initial_state: The app's initial state
#   transform: Takes a reference to state, action, and options. Must mutate
#              the state to transition to the new state. True or false depending
#              on whether the message was valid or not.

SUPPORTED_APPS = { 'chat' => Chat, 'tictactoe' => TicTacToe }.freeze

before do
  content_type :json
end

$app_sessions = {}

# Creates an initial state given the name of a app.
def create_initial_state(app)
  raise 'Invalid app' unless SUPPORTED_APPS[app]
  SUPPORTED_APPS[app].initial_state
end

# Gets all state for a session. Don't send this anywhere!
def all_state(id)
  $app_sessions[id][:state]
end

# Gets the public state for a session.
def public_state(id)
  all_state(id).reject { |k, v| k.to_s.start_with? "_", "$" }
end

# Gets the public state for a session, including any locked state for a session
# given a caller-supplied key. Locked state objects must be at the top level
# of an object's session.
def locked_state(id, key)
  # If there's no key, or no locked state for that key, just return public state
  locked = all_state(id)[:"$#{key}"]
  return public_state(id) if key.nil? || locked.nil?

  public_state(id).merge(:"$#{key}" => locked)
end

get '/apps' do
  { apps: SUPPORTED_APPS.keys }.to_json
end

get '/apps/:app/new' do
  app = params['app']

  # Assign a random ID which one could read out
  new_id = SecureRandom.urlsafe_base64 4

  halt 403, { response: 'Invalid app' }.to_json unless
  SUPPORTED_APPS[app]

  # Create a new session
  app_session = {
    id: new_id,
    app: app,
    state: create_initial_state(app)
  }

  # Add to the app_sessions array
  $app_sessions[new_id] = app_session

  # Return ID
  { id: new_id }.to_json
end

get '/apps/:id/state' do
  id = params['id']

  halt 404, '{}' unless $app_sessions[id]

  public_state(id).to_json
end

post '/apps/:id/state' do
  id = params['id']

  halt 404, '{}' unless $app_sessions[id]

  options = JSON.parse(request.body.read)
  key = options['key']

  locked_state(id, options['key']).to_json
end

post '/apps/:id/message' do
  id = params['id']

  halt 404, '{}' unless $app_sessions[id]

  app = SUPPORTED_APPS[$app_sessions[id][:app]]

  options = JSON.parse(request.body.read)
  action = options['action']

  halt 401, { error: 'Invalid' }.to_json unless app.transform(all_state(id), action, options)

  locked_state(id, options['key']).to_json
end
