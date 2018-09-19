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

      # Find player locked state keys
      locked_state_keys = state.select { |k, v| k.to_s.start_with? '$' }.keys

      # TODO: What if the deck is empty?
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
      state[:players][player_id][:bet] = bet_amount
      state[:players][player_id][:money] -= bet_amount

      true
    when 'flop'
      # Draw three cards
      # TODO: Check anything whatsoever

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
    else
      false
    end
  end
end
