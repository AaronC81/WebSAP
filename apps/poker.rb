require_relative "../app_helpers.rb"
require 'ruby-poker'

START_DECK = ["10c","10d","10h","10s","2c","2d","2h","2s","3c","3d","3h","3s","4c","4d","4h","4s","5c","5d","5h","5s","6c","6d","6h","6s","7c","7d","7h","7s","8c","8d","8h","8s","9c","9d","9h","9s","Ac","Ad","Ah","As","Jc","Jd","Jh","Js","Kc","Kd","Kh","Ks","Qc","Qd","Qh","Qs"]

# A poker app.
class Poker
  extend AppHelpers

  def self.name
    'tictactoe'
  end

  def self.initial_state
    # Phases: waiting, start, flop, turn, river, end
    # TODO: Make deck reset on end
    {
      players: {},
      phase: 'waiting',
      table: [],
      _deck: START_DECK.clone,
      winners: [],
      win_description: nil
    }
  end

  def self.initial_public_player_state
    {
      nickname: nil,
      money: 1000,
      bet: 0,
      has_folded: false,
      revealed_cards: []
    }
  end

  def self.initial_locked_player_state
    {
      hole_cards: [],
      player_id: 0
    }
  end

  def self.rank(hole, table)
    # The lib wants T rather than 10
    hand = PokerHand.new((hole + table).map { |x| x.gsub('10', 'T') })
    [hand.score.first.first, hand.hand_rating]
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
      state[:winners] = []
      state[:win_description] = nil

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

        # Reset them
        state[:players][player_id][:bet] = 0
        state[:players][player_id][:has_folded] = false
        state[:players][player_id][:revealed_cards] = []
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

      # Find player locked state keys
      locked_state_keys = state.select { |k, v| k.to_s.start_with? '$' }.keys

      # Find how many players are still playing (i.e. not folded)
      active_players = []
      locked_state_keys.each do |key|
        # Get their player ID
        this_player_id = state[key][:player_id]

        active_players << this_player_id unless state[:players][this_player_id][:has_folded]
      end

      # If there's only one player left...
      if active_players.length == 1
        # End the round
        state[:phase] = 'end'
        state[:winners] = active_players
        state[:win_description] = 'all folded'

        # Calculate the pot and reveal cards
        pot = 0
        locked_state_keys.each do |key|
          this_player_id = state[key][:player_id]
          pot += state[:players][this_player_id][:bet]
          state[:players][this_player_id][:revealed_cards] = state[key][:hole_cards]
        end

        # Award the pot
        state[:players][active_players.first][:money] += pot
      end

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

      true
    when 'end'
      state[:phase] = 'end'

      # Find player locked state keys
      locked_state_keys = state.select { |k, v| k.to_s.start_with? '$' }.keys

      pot = 0
      highest_score = -1
      highest_score_players = []
      highest_score_desc = ""
      # For each player...
      locked_state_keys.each do |key|
        # Get their player ID
        player_id = state[key][:player_id]

        # Get their hole cards
        hole_cards = state[key][:hole_cards]

        # Reveal their cards
        state[:players][player_id][:revealed_cards] = hole_cards

        # Work out their score
        score, desc = rank(hole_cards, state[:table])

        # Check if it's joint highest
        if score == highest_score
          highest_score_players << player_id
        end

        # Check if it's the new highest score
        if score > highest_score
          highest_score = score
          highest_score_players = [player_id]
          highest_score_desc = desc
        end

        # Add their bet to the pots
        pot += state[:players][player_id][:bet]
      end

      # Set the winner
      state[:winners] = highest_score_players
      state[:win_description] = highest_score_desc

      # Award them the pot
      highest_score_players.each do |winning_id|
        state[:players][winning_id][:money] += pot / highest_score_players.length
      end
    else
      false
    end
  end
end
