require_relative "../app_helpers.rb"

def same?(arr)
  arr.uniq.length == 1
end

# This showcases how a 'player' system might work.
# Don't identify players by their key, because then other people could pretend
# to be them.
# Instead, assign them a user number in their locked state.

# A Tic Tac Toe app.
class TicTacToe
  extend AppHelpers

  def self.name
    'tictactoe'
  end

  def self.winner(board)
    # Check for a row win
    (0..2).each do |row|
      return board[row][0] if same? [board[row][0], board[row][1], board[row][2]]
    end

    # Check for a column win
    (0..2).each do |col|
      return board[0][col] if same? [board[0][col], board[1][col], board[2][col]]
    end

    # Check /
    return board[2][0] if same? [board[2][0], board[1][1], board[0][2]]

    # Check \
    return board[2][2] if same? [board[2][2], board[1][1], board[0][0]]

    # Check if the board is full
    return "?" unless board.flatten.include? nil

    nil
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

      # Set winner
      state[:winner] = winner(state[:board])

      true
    when 'restart'
      # Resets the game. ASSUMES THAT TWO PLAYERS ARE CONNECTED.

      state[:phase] = 'turn'
      state[:phase_player] = initial_state[:phase_player]
      state[:board] = initial_state[:board]
      state[:winner] = initial_state[:winner]

      true
    else
      false
    end
  end
end