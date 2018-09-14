require_relative "../app_helpers.rb"

# This showcases how a 'player' system might work.
# Don't identify players by their key, because then other people could pretend
# to be them.
# Instead, assign them a user number in their locked state.

# A Tic Tac Toe app.
class TicTacToe
  extend AppHelpers

  def self.name
    "tictactoe"
  end

  def self.initial_state
    # Locked state has: { player_id: ... }
    # Other phase: 'turn'
    {
      players: {},
      phase: 'waiting',
      phase_player: 'X',
      board: [
        [nil,nil,nil],
        [nil,nil,nil],
        [nil,nil,nil]
      ],
      winner: nil
    }
  end

  def self.transform(state, action, options)
    @next_player_id ||= 1
    state[hlkey(options)] ||= {}

    case action
    when 'join'
      # Register this player - use strings in case we don't use numbers in
      # the future
      state[hlkey(options)][:player_id] = @next_player_id.to_s
      this_player = @next_player_id.to_s
      @next_player_id += 1

      # Assign them a role
      # TODO: Work off phases rather than player length?
      case state[:players].length
      when 0
        state[:players][this_player] = 'X'

        # We're waiting for 'O' now
        state[:phase_player] = 'O'
      when 1
        state[:players][this_player] = 'O'

        # Start the game, it's X's turn
        state[:phase] = 'turn'
        state[:phase_player] = 'X'
      else
        state[:players][this_player] = 'S'
      end
      true
    when 'move'
      # Check we're actually expecting a move
      return false unless state[:phase] == 'turn'

      # Find out which player made the request
      player_id = state[hlkey(options)][:player_id]
      player_role = state[:players][player_id]

      # Check it's who we were expecting to make the move
      return false unless state[:phase_player] == player_role

      # Get row and column from request
      # TODO: Check not already filled
      row = options['row'].to_i
      col = options['col'].to_i
      p options

      # Make change to board
      state[:board][row][col] = player_role

      # Transition to other player
      state[:phase_player] = (state[:phase_player] == 'X' ? 'O' : 'X')

      true
    else
      false
    end
  end
end