module Messages
  def invalid_message
    Display.prompt "Invalid entry, please try again"
  end
end

module Calculator
  @@max_total = 21

  def self.max_total=(max_total)
    @@max_total = max_total
  end

  def calculate_total(hand)
    total = 0
    hand.each do |card|
      if card.ace?
        total += 11
      elsif card.face?
        total += 10
      else
        total += card.face.to_i
      end
    end
    number_of_aces = hand.select(&:ace?).size
    total = correct_for_aces(total, number_of_aces)
    total
  end

  def correct_for_aces(total, number_of_aces)
    until total <= @@max_total || number_of_aces < 1
      total -= 10
      number_of_aces -= 1
    end
    total
  end
end

class Player
  HIT = :hit
  STAY = :stay
  DECISIONS = [HIT, STAY]

  include Calculator
  attr_reader :hand, :name, :total

  def initialize

    clear_hand
    choose_name
  end

  def add_to_hand(card)
    @hand << card
    @total = calculate_total(hand)
  end

  def clear_hand
    @hand = []
  end

  def busted?
  end
end

class Human < Player
  attr_reader :label

  def initialize(label = "Player 1")
    @label = label
    super()
  end

  def make_decision
    :stay
  end

  def choose_name
    chosen_name = prompt_for_name
    @name = chosen_name
  end

  def prompt_for_name
    loop do
      Display.prompt("Please enter #{label}'s name: ")
      chosen_name = gets.chomp

      return chosen_name if valid_name?(chosen_name)
      invalid_message
    end
  end

  def valid_name?(chosen_name)
    !chosen_name.empty? && !chosen_name.start_with?(' ')
  end
end

class Computer < Player
  def make_decision
    DECISIONS.sample
  end

  def choose_name
    @name = ["Magic Head", "Galileo Humpkins",
             "Hollabackatcha", "Methuselah Honeysuckle",
             "Ovaltine Jenkins", "Felicia Fancybottom"].sample
  end
end

class Dealer < Computer
  attr_accessor :deck

  def deal_card
    deck.cards.shift
  end

  def choose_name
    @name = "Dealer"
  end
end

class Deck
  attr_accessor :cards

  def initialize(num_players)
    @cards = []
    num_decks = calculate_num_decks(num_players)
    create_deck(num_decks)
    shuffle_deck
  end

  def calculate_num_decks(num_players)
    (num_players/4.0).ceil
  end

  def create_deck(num_decks)
    num_decks.times do 
      Card::SUITS.each do |suit|
        Card::FACES.each do |face|
          @cards << Card.new(face, suit)
        end
      end
    end
  end

  def shuffle_deck
    cards.shuffle!
  end
end

class Card
  SUITS = ['H', 'D', 'S', 'C']
  FACES = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']

  attr_reader :face, :suit

  def initialize(face, suit)
    @face = face
    @suit = suit
  end

  def ace?
    face == "A"
  end

  def face?
    %w(J Q K).include?(face)
  end

end

class Display
  SUIT_SYMBOL = {
    "H" => "\u2665".encode('utf-8'),
    "D" => "\u2666".encode('utf-8'),
    "C" => "\u2663".encode('utf-8'),
    "S" => "\u2660".encode('utf-8')
  }

  HIDDEN_CARD = <<-CARD
    ---------
    |XXXXXXX|
    |XXXXXXX|
    |XXXXXXX|
    |XXXXXXX|
    |XXXXXXX|
    ---------
  CARD

  def self.prompt(message)
    puts "==> #{message}"
  end

  def refresh(active_players)
    system 'clear'
    players_to_display = active_players[0...-1]
    dealer = active_players.last

    players_to_display.each do |player|
      display_total(player)
      display_hand(player.hand)
    end
    display_hand(dealer.hand, true)
  end
  
  private

  def display_total(player)
    puts "#{player.name} has #{player.total}"
  end

  def display_hand(player_hand, hide_second_card = false)
    card_strings = player_hand.map do |card| 
                     card_to_s(card.face, card.suit)
                   end

    card_strings[-1] = HIDDEN_CARD if hide_second_card

    hand_string = join_multiline_strings(card_strings)
    puts hand_string
  end

  def join_multiline_strings(strings)
    num_of_lines = strings.first.count("\n")

    joined_string = ""
    0.upto(num_of_lines - 1) do |line_number|
      string_line = ""
      strings.each do |string|
        lines = string.lines
        string_line << lines[line_number].chomp
      end
      joined_string << string_line + "\n"
    end
    joined_string
  end

  def card_to_s(face, suit)
    suit = SUIT_SYMBOL[suit]
    card = <<-CARD
    ---------
    |#{face.center(3)}    |
    |       |
    |   #{suit}   |
    |       |
    |    #{face.center(3)}|
    ---------
    CARD
    card
  end
end



class PlayerFactory
  attr_reader :num_humans, :humans_created

  def initialize(num_humans)
    @num_humans = num_humans
    @humans_created = 0
  end

  def build_player
    if humans_created < num_humans
      label = "Player #{humans_created + 1}"
      player = Human.new(label)
      @humans_created += 1
    else
      player = Dealer.new
    end
    player
  end
end

class TwentyOneGame
  include Messages
  attr_reader :display, :deck, :players, :dealer, :active_players, :game_number, :max_total

  def initialize
    @game_number = 0
    @max_total = 21
  end
  
  def play
    display_welcome_message
    setup_game
    play_game
    finish_game
    display_goodbye_message
  end

  def display_welcome_message
    Display.prompt("Welcome to Twenty-One!")
  end

  def setup_game
    if game_number == 0 
      build_players
      Calculator.max_total = max_total
    else
      clear_player_hands
    end
    
    @display = Display.new
    @deck = Deck.new(players.size)
    @dealer.deck = deck
    deal_initial_hands
    @active_players = []
  end

  def build_players
    players = []
    num_humans = prompt_for_num("humans", 1)
    factory = PlayerFactory.new(num_humans)
    
    1.upto(num_humans + 1) do
      players << factory.build_player
    end

    @dealer = players.last
    @players = players
  end

  def prompt_for_num(type, minimum)
    number = nil
    loop do
      Display.prompt("How many total #{type}? (must be more than #{minimum})")
      number = gets.chomp
      break if valid_num_choice?(number, minimum)
      invalid_message
    end
    number.to_i
  end

  def valid_num_choice?(input, minimum=1)
     valid_integer?(input) && 
       input.to_i >= minimum
  end

  def valid_integer?(input)
    input == input.to_i.to_s && 
      input != '0'
  end

  def clear_player_hands
    players.each do |player|
      player.clear_hand
    end
  end

  def deal_initial_hands
    2.times do 
      players.each do |player|
        card = dealer.deal_card
        player.add_to_hand(card)
      end
    end
  end

  def play_game
    players.each do |player|
      @active_players << player
      take_turn(player)
    end
  end

  def take_turn(player)
    loop do
      display.refresh(active_players)
      decision = player.make_decision
      break if decision == Player::STAY

      card = dealer.deal_card
      player.add_to_hand(card)
    end
  end
  
  def finish_game
    @game_number += 1
  end

  def display_goodbye_message
    Display.prompt("Thanks for playing Twenty-One!")
  end
end

TwentyOneGame.new.play