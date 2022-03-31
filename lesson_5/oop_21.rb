require 'pry'
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
  DECISIONS = {
    "h" => HIT,
    "hit" => HIT,
    "s" => STAY,
    "stay" => STAY
  }
  
  include Messages
  include Calculator
  attr_accessor :has_played
  attr_reader :hand, :name, :total, :score

  def initialize
    @score = 0
    clear_hand
    choose_name
  end

  def add_to_hand(card)
    @hand << card
    refresh_total
  end

  def refresh_total
    @total = calculate_total(hand)
  end

  def first_card_value
    calculate_total([hand.first])
  end

  def clear_hand
    @hand = []
  end

  def busted?
    total > @@max_total
  end

  def scored
    @score += 1
  end
end

class Human < Player
  attr_reader :label

  def initialize(label = "Player 1")
    @label = label
    super()
  end

  def make_decision
    decision = prompt_for_decision
    decision
  end

  def prompt_for_decision
    input = nil
    loop do
      Display.prompt("#{name}'s turn, hit or stay? (h/s)")
      input = gets.chomp.downcase
      break if hit_or_stay?(input)
      invalid_message
    end
    DECISIONS[input]
  end

  def hit_or_stay?(input)
    %w(h hit s stay).include?(input)
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
  @@names_taken = []

  def make_decision
    sleep(1)
    refresh_total
    if total < @@max_total - 3
      HIT
    else
      STAY
    end
  end

  def choose_name
    name = nil
    loop do
      name = ["Magic Head", "Galileo Humpkins",
              "Hollabackatcha", "Methuselah Honeysuckle",
              "Ovaltine Jenkins", "Felicia Fancybottom"].sample
      break unless @@names_taken.include?(name)
    end
    @@names_taken << name
    @name = name 
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

class PlayerFactory
  attr_reader :humans_created
  
  def initialize
    @humans_created = 0
  end

  def build_player(type)
    case type
    when :human
      label = "Player #{humans_created + 1}"
      player = Human.new(label)
      @humans_created += 1
    when :computer
      player = Computer.new
    else
      player = Dealer.new
    end
    player
  end
end

class Deck
  attr_accessor :cards

  def initialize(num_players)
    @cards = []
    num_decks = calculate_num_decks(num_players)
    create_deck(num_decks)
    shuffle
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

  def shuffle
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

  attr_reader :max_cards, :span, :players, :number_of_players

  def initialize(players)
    @players = players
    @span = [(max_name_size + 2), 12].max
    @number_of_players = players.size
  end

  def self.prompt(message)
    puts "==> #{message}"
  end

  def refresh
    active, inactive = players.partition do |player|
                                           player.has_played
                                         end
    system 'clear'
    find_max_cards(active)
    display_scoreboard
    display_players(active)
    puts horizontal_rule
    display_players(inactive, true)
  end
  
  private
  
  def max_name_size
    player_names = players.map { |player| player.name }
    player_name_sizes = player_names.map { |name| name.size }
    player_name_sizes.max
  end

  def display_scoreboard
    scoreboard = build_scoreboard
    puts scoreboard
  end

  def build_scoreboard
    line = scoreboard_line
    names = "|"
    scores = "|"

    players.each do |player|
      names << "#{name_of(player)}|"
      scores << "#{score_of(player)}|"
    end

    <<-SCOREBOARD
    #{line}
    #{names}
    #{scores}
    #{line}
    SCOREBOARD
  end

  def name_of(player)
    player.name.center(span)
  end

  def score_of(player)
    score = format_score(player.score)
    score.center(span)
  end

  def find_max_cards(players)
    hands = players.map { |player| player.hand }
    hand_sizes = hands.map { |hand| hand.size }
    @max_cards = hand_sizes.max
  end

  def scoreboard_line
    line = "+"
    number_of_players.times do
      line << "-" * span + "+"
    end
    line
  end

  def format_score(score)
    score.to_s.rjust(2, '0')
  end

  def heading(title)
    title.center((span * 2) + MARGIN_SIZE, '-').to_s
  end

  def display_players(active_players, hide_last_card = false)
    active_players.each do |player|
      display_state(player, hide_last_card)
      display_hand(player.hand, hide_last_card)
    end
  end

  def display_state(player, hide_last_card = false)
    total = hide_last_card ? player.first_card_value : player.total
    puts "#{player.name} has #{total}"
    puts "#{player.name} busted :(" if player.busted?
  end

  def display_hand(player_hand, hide_last_card = false)
    card_strings = player_hand.map do |card| 
                     card_to_s(card.face, card.suit)
                   end

    card_strings[-1] = HIDDEN_CARD if hide_last_card

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

  def horizontal_rule
    "-" * 13 * max_cards
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

class TwentyOneGame
  HUMAN = :human
  COMPUTER = :computer
  DEALER = :dealer

  include Messages
  attr_reader :display, :deck, :players, :dealer, :game_number,
              :max_total, :player_factory, :winners

  def initialize
    @game_number = 0
    @max_total = 21
    @players = []
    @player_factory = PlayerFactory.new
  end
  
  def play
    welcome_message
    loop do
      setup_game
      play_game
      finish_game
      break unless play_again?
    end
    goodbye_message
  end

  private

  def setup_game
    if game_number == 0 
      build_players
      Calculator.max_total = max_total
      @display = Display.new(players)
    end

    reset_game_space
    deal_initial_hands
  end

  def build_players
    num_humans = prompt_for_num(HUMAN, 1, 3)
    num_comps = prompt_for_num(COMPUTER, 0, 2)

    add_players_to_game(num_humans, HUMAN)
    add_players_to_game(num_comps, COMPUTER)
    add_players_to_game(1, DEALER)

    @dealer = players.last
  end

  def add_players_to_game(count, type)
    1.upto(count) do
      @players << player_factory.build_player(type)
    end
  end

  def prompt_for_num(type, minimum, maximum)
    number = nil
    loop do
      Display.prompt("How many #{type}s? (#{minimum} to #{maximum})")
      number = gets.chomp
      break if valid_num_choice?(number, minimum, maximum)
      invalid_message
    end
    number.to_i
  end

  def valid_num_choice?(input, minimum, maximum)
     valid_integer?(input) && 
       input.to_i >= minimum &&
       input.to_i <= maximum
  end

  def valid_integer?(input)
    input == input.to_i.to_s
  end

  def reset_game_space
    reset_players
    @winners = []
    @deck = Deck.new(players.size)
    @dealer.deck = deck
  end

  def reset_players
    players.each do |player|
      player.clear_hand
      player.has_played = false
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
      player.has_played = true
      take_turn(player)
    end
  end

  def take_turn(player)
    loop do
      display.refresh
      decision = player.make_decision
      break if player_stayed?(decision)

      card = dealer.deal_card
      player.add_to_hand(card)
      break if player.busted?
    end
  end

  def player_stayed?(decision)
    decision == Player::STAY
  end
  
  def finish_game
    determine_winners
    display.refresh
    game_over_message
    @game_number += 1
  end

  def determine_winners
    if dealer.busted?
      compare_scores(0)
    else
      compare_scores(dealer.total)
      winners << dealer if winners.empty?
      dealer.scored
    end
  end

  def compare_scores(total)
    players.each do |player|
      if player.total > total && !player.busted?
        @winners << player
        player.scored
      end
    end
  end

  def play_again?
    play_again = prompt_for_play_again
    play_again
  end

  def prompt_for_play_again
    play_again = nil
    loop do
      Display.prompt "Would you like to play again? (y/n)"
      play_again = gets.chomp.downcase
      break if valid_yes_or_no?(play_again)
      invalid_message
    end
    play_again == 'y' || play_again == 'yes'
  end

  def valid_yes_or_no?(choice)
    %w(y n yes no).include?(choice)
  end

  def welcome_message
    Display.prompt "Welcome to Twenty-One!"
  end

  def goodbye_message
    Display.prompt "Thanks for playing Twenty-One!"
  end

  def game_over_message
    if winners.empty?
      puts "Nobody won!"
    else
      names = winners.map { |winner| winner.name }
      puts joinor(names, ', ', 'and') + " won!"
    end
  end

  def joinor(items, delim=', ', tail='or')
    return items[-1].to_s if items.size == 1
    items[0...-1].join(delim) +
      ' ' + tail + ' ' +
      items[-1].to_s
  end
end

TwentyOneGame.new.play