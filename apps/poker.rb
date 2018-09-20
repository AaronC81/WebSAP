require_relative "../app_helpers.rb"

START_DECK = ["10c","10d","10h","10s","2c","2d","2h","2s","3c","3d","3h","3s","4c","4d","4h","4s","5c","5d","5h","5s","6c","6d","6h","6s","7c","7d","7h","7s","8c","8d","8h","8s","9c","9d","9h","9s","Ac","Ad","Ah","As","Jc","Jd","Jh","Js","Kc","Kd","Kh","Ks","Qc","Qd","Qh","Qs"]

# A poker app.
class Poker
  extend AppHelpers

  def self.name
    'tictactoe'
  end

  def self.initial_state
    # Phases: waiting, start, flop, turn, river
    # TODO: Make deck reset on end
    {
      players: {},
      phase: 'waiting',
      table: [],
      _deck: START_DECK.clone,
    }
  end

  def self.initial_public_player_state
    {
      nickname: nil,
      money: 1000,
      bet: 0,
      has_folded: false
    }
  end

  def self.initial_locked_player_state
    {
      hole_cards: [],
      player_id: 0
    }
  end

  def self.transform(state, action, options)
    @next_player_id ||= 1
    state[hlkey(options)] ||= {}

    case action
    when 'join'
      # Register this player - use strings in case we don't use numbers in
      # the future
      state[hlkey(options)] = initial_locked_player_state
      state[hlkey(options)][:player_id] = @next_player_id.to_s
      this_player = @next_player_id.to_s
      @next_player_id += 1

      state[:players][this_player] = initial_public_player_state
      state[:players][this_player][:nickname] = options['nickname']

      true
    when 'start'
      # Start the round
      state[:phase] = 'start'
      state[:table] = []
      state[:_deck] = START_DECK.clone

      # Find player locked state keys
      locked_state_keys = state.select { |k, v| k.to_s.start_with? '$' }.keys

      # For each player...
      locked_state_keys.each do |key|
        # Get their player ID
        player_id = state[key][:player_id]

        # Find them two cards
        first_card = state[:_deck].sample
        state[:_deck].delete first_card
        second_card = state[:_deck].sample
        state[:_deck].delete second_card

        # Give them the cards
        state[key][:hole_cards] = [first_card, second_card]

        # Reset their bet
        state[:players][player_id][:bet] = 0
        state[:players][player_id][:has_folded] = false
      end

      true
    when 'bet'
      # Get the better's player ID
      player_id = state[hlkey(options)][:player_id]

      # Get their bet amount
      bet_amount = options['amount'].to_i

      # Check they've got enough money
      return false if bet_amount > state[:players][player_id][:money]

      # Set their bet and remove it from their balance
      state[:players][player_id][:bet] += bet_amount
      state[:players][player_id][:money] -= bet_amount

      true
    when 'fold'
      # Fold the player
      player_id = state[hlkey(options)][:player_id]
      state[:players][player_id][:has_folded] = true

      # TODO: Check if there's only one player left, if so reward them and start
      #       again

      true
    when 'flop'
      # Draw three cards
      # TODO: Check anything whatsoever

      state[:phase] = 'flop'

      first_card = state[:_deck].sample
      state[:_deck].delete first_card
      second_card = state[:_deck].sample
      state[:_deck].delete second_card
      third_card = state[:_deck].sample
      state[:_deck].delete third_card

      state[:table] << first_card
      state[:table] << second_card
      state[:table] << third_card

      true
    when 'turn'
      # Draw one card
      # TODO: Check anything whatsoever

      state[:phase] = 'turn'

      fourth_card = state[:_deck].sample
      state[:_deck].delete fourth_card
      
      state[:table] << fourth_card

      true
    when 'river'
      # Draw one card
      # TODO: Check anything whatsoever

      state[:phase] = 'river'

      fifth_card = state[:_deck].sample
      state[:_deck].delete fifth_card
      
      state[:table] << fifth_card

      # TODO: Find winner
      true
    else
      false
    end
  end
end
