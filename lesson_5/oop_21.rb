module Calculator
  @@game_mode = 21

  def self.game_mode=(game_mode)
    @@game_mode = game_mode
  end

  def calculate_total(hand)
    total = 0
    hand.each do |card|
      total += calculate_card_total(card)
    end
    number_of_aces = hand.select(&:ace?).size
    total = correct_for_aces(total, number_of_aces)
    total
  end

  def calculate_card_total(card)
    if card.ace?
      11
    elsif card.face?
      10
    else
      card.face.to_i
    end
  end

  def correct_for_aces(total, number_of_aces)
    until total <= @@game_mode || number_of_aces < 1
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
    total > @@game_mode
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
      Display.invalid
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
      Display.invalid
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
    if total < @@game_mode - 3
      HIT
    else
      STAY
    end
  end

  def choose_name
    name = nil
    loop do
      name = ["Magic Head", "Galileo Humpkins", "Medulla Oblongata",
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
      @humans_created += 1
      label = "Player #{humans_created}"
      Human.new(label)
    when :computer
      Computer.new
    else
      Dealer.new
    end
  end
end

class Deck
  attr_accessor :cards

  def initialize(num_players, game_mode)
    @cards = []
    num_decks = calculate_num_decks(num_players, game_mode)
    create_deck(num_decks)
    shuffle
  end

  def calculate_num_decks(num_players, game_mode)
    max_deck_value = 340.0 - (10 * num_players)
    ((num_players * game_mode) / max_deck_value).ceil
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
  INDENT = " " * 4
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

  attr_accessor :title
  attr_reader :span, :players, :number_of_players

  def setup(players)
    @players = players
    @span = [(max_name_size + 2), 12].max
    @number_of_players = players.size
  end

  def self.prompt(message)
    puts "==> #{message}"
  end

  def self.invalid
    prompt "Invalid entry, please try again"
  end

  def refresh
    active, inactive = players.partition(&:has_played)

    system 'clear'
    display_title
    display_scoreboard
    display_players(active)
    puts horizontal_rule
    display_players(inactive, true)
  end

  def modes(game_modes)
    game_modes.each_with_index do |mode, index|
      selection = index + 1
      puts "#{selection}) #{mode}\n"
    end
  end

  def welcome
    Display.prompt "Welcome to #{title}!"
  end

  def goodbye
    Display.prompt "Thanks for playing #{title}!"
  end

  def game_over(winners)
    names = winners.map(&:name)
    puts joinor(names, ', ', 'and') + " won!"
  end

  private

  def max_name_size
    player_names = players.map(&:name)
    player_name_sizes = player_names.map(&:size)
    player_name_sizes.max
  end

  def display_title
    puts horizontal_rule(title)
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

  def display_players(active_players, hide_last_card = false)
    active_players.each do |player|
      display_state(player, hide_last_card)
      display_hand(player.hand, hide_last_card)
    end
  end

  def display_state(player, hide_last_card = false)
    total = hide_last_card ? player.first_card_value : player.total
    puts INDENT + "#{player.name} has #{total}"
    puts INDENT + "#{player.name} busted :(" if player.busted?
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
      joined_line = join_line(strings, line_number)
      joined_string << joined_line + "\n"
    end
    joined_string
  end

  def join_line(strings, line_number)
    joined_line = ""
    strings.each do |string|
      lines = string.lines
      joined_line << lines[line_number].chomp
    end
    joined_line
  end

  def horizontal_rule(title = "")
    length = scoreboard_line.size
    INDENT + title.center(length, '-')
  end

  def card_to_s(face, suit)
    suit = SUIT_SYMBOL[suit]
    <<-CARD
    ---------
    |#{face.center(3)}    |
    |       |
    |   #{suit}   |
    |       |
    |    #{face.center(3)}|
    ---------
    CARD
  end

  def joinor(items, delim=', ', tail='or')
    return items[-1].to_s if items.size == 1
    items[0...-1].join(delim) +
      ' ' + tail + ' ' +
      items[-1].to_s
  end
end

class TwentyOneGame
  HUMAN = :human
  COMPUTER = :computer
  DEALER = :dealer
  TITLE = {
    21 => "Twenty-One",
    31 => "Thirty-One",
    41 => "Fourty-One",
    51 => "Fifty-One",
    61 => "Sixty-One",
    71 => "Seventy-One",
    81 => "Eighty-One",
    91 => "Ninety-One",
    101 => "One-O-One",
    111 => "Eleventy-One"
  }
  GAME_MODES = TITLE.keys

  attr_reader :display, :deck, :players, :dealer, :game_number,
              :game_mode, :player_factory, :winners, :title

  def initialize
    @game_number = 0
    @display = Display.new
    @player_factory = PlayerFactory.new
    @players = []

    determine_game_mode
    determine_title
  end

  def play
    display.welcome
    loop do
      setup_game
      play_game
      finish_game
      break unless play_again?
    end
    display.goodbye
  end

  private

  def determine_game_mode
    mode = prompt_for_game_mode
    @game_mode = GAME_MODES[mode - 1]
    Calculator.game_mode = game_mode
  end

  def prompt_for_game_mode
    mode = nil
    loop do
      Display.prompt("Please select a game mode:")
      display.modes(TITLE.values)
      mode = gets.chomp
      break if valid_mode?(mode)
      Display.invalid
    end
    mode.to_i
  end

  def valid_mode?(mode)
    selections = *(1..GAME_MODES.size)
    selections.include?(mode.to_i)
  end

  def determine_title
    @title = TITLE[game_mode]
    display.title = title
  end

  def setup_game
    if game_number == 0
      build_players
      display.setup(players)
    end

    reset_game_space
    deal_initial_hands
  end

  def build_players
    num_humans = prompt_for_num(HUMAN, 1, 2)
    max_comps = 4 - num_humans
    num_comps = prompt_for_num(COMPUTER, 0, max_comps)

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
      Display.invalid
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
    @deck = Deck.new(players.size, game_mode)
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
      break if dealer.has_played && dealer_wins_by_default?

      decision = player.make_decision
      break if player_stayed?(decision)

      card = dealer.deal_card
      player.add_to_hand(card)
      break if player.busted?
    end
  end

  def dealer_wins_by_default?
    non_dealer_players = players[0...-1]
    non_dealer_players.all? do |player|
      player.total <= dealer.total || player.busted?
    end
  end

  def player_stayed?(decision)
    decision == Player::STAY
  end

  def finish_game
    determine_winners
    display.refresh
    display.game_over(winners)
    @game_number += 1
  end

  def determine_winners
    if dealer.busted?
      compare_scores(0)
    else
      compare_scores(dealer.total)
      if winners.empty?
        winners << dealer
        dealer.scored
      end
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
      Display.invalid
    end
    play_again == 'y' || play_again == 'yes'
  end

  def valid_yes_or_no?(choice)
    %w(y n yes no).include?(choice)
  end
end

TwentyOneGame.new.play
