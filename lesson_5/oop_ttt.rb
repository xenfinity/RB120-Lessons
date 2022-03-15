require 'pry'
module Invalid
  def invalid
    puts "Invalid entry, please try again"
  end
end

class Square
  attr_reader :state

  def initialize(state=nil)
    @state = state
  end
  
  def to_s
    state ? state.to_s : " "
  end

  def mark(state)
    @state = state
  end

  def clear
    @state = nil
  end
  
end

class Board
  @@all_spaces = *(1..9)
  attr_reader :board, :available_spaces

  def initialize
    @available_spaces = *(1..9)
    build_board
  end

  def all_spaces
    @@all_spaces
  end

  def state_of(position)
    board[position].state
  end

  def build_board
    @board = Hash.new
    1.upto(9) do |i|
      square = Square.new
      @board[i] = square
    end
  end

  def mark_square(position, game_piece)
    @board[position].mark(game_piece)
    available_spaces.delete(position)
  end

  def reset
    @available_spaces = *(1..9)
    build_board
  end

  def to_s
    board_to_s = <<-BOARD
    
         |     |
      #{board[1]}  |  #{board[2]}  |  #{board[3]}
    _____|_____|_____
         |     |
      #{board[4]}  |  #{board[5]}  |  #{board[6]}
    _____|_____|_____
         |     |
      #{board[7]}  |  #{board[8]}  |  #{board[9]}
         |     |
    
    BOARD
    board_to_s
  end
end

class Map < Board

  def build_board
    @board = Hash.new
    1.upto(9) do |i|
      square = Square.new(i)
      @board[i] = square
    end
  end

  def clear(position)
    @board[position].clear
  end

  def to_s
    "-----------MAP-----------\n" + super
  end
end

class Player
  attr_accessor :game_piece
  attr_reader :score, :name, :board, :available_spaces

  def initialize(board)
    @board = board
    @score = 0
    choose_name
    @available_spaces = board.available_spaces
  end

  def reset
    @available_spaces = board.available_spaces
  end

  def to_s
    "#{name}'s turn, you are #{game_piece}'s!"
  end

  def increment_score
    @score += 1
  end
  
end

class Human < Player

  attr_reader :label

  def initialize(board, label="Player 1")
    @label = label
    super(board)
  end

  def choose_name  
    chosen_name = nil
    loop do
      puts "Please enter #{label}'s name: "
      chosen_name = gets.chomp
  
      break unless chosen_name.empty?
      puts "Name cannot be blank"
    end
    @name = chosen_name
  end

  def choose_position
    prompt_for_position
  end

  def prompt_for_position
    loop do
      puts "Choose a square (#{joinor(available_spaces)}): "
      input = gets.chomp
  
      return input.to_i if valid_choice?(input)
    end
  end

  def joinor(items, delim=', ', tail='or')
    items[0...-1].join(delim) +
      ' ' + tail + ' ' +
      items[-1].to_s
  end

  def valid_choice?(input)
    unless input == input.to_i.to_s && available_spaces.include?(input.to_i)
      puts "Invalid choice, please enter a number from the available spaces"
      return false
    end
    true
  end
end

class Computer < Player
  CORNERS = [1, 3, 7, 9]
  CENTER = 5
  WIN_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9],
              [1, 4, 7], [2, 5, 8], [3, 6, 9],
              [1, 5, 9], [7, 5, 3]]

  OPP_PIECE = {
    X: :O,
    O: :X
  }

  DIFFICULTIES = {
    'e' => :easy,
    'easy' => :easy,
    'h' => :hard,
    'hard' => :hard
  }

  include Invalid
  attr_reader :difficulty, :opponent_piece, :positions_occupied
  
  def initialize(board)
    super
    select_difficulty
  end

  def game_piece=(piece)
    @game_piece = piece
    @opponent_piece = OPP_PIECE[piece]
  end

  def select_difficulty
    difficulty = nil
    loop do
      puts "Please select a difficulty - Easy(e) or Hard(h): "
      difficulty = gets.chomp.downcase
  
      break if %w(e h easy hard).include?(difficulty)
      invalid
    end
    @difficulty = DIFFICULTIES[difficulty]
  end

  def choose_name  
    @name = ["Magic Head", "Galileo Humpkins", 
             "Hollabackatcha", "Methuselah Honeysuckle"].sample
  end

  def choose_position
    if difficulty == :easy
      choose_easy 
    else
      choose_hard
    end
  end

  def choose_easy
    available_spaces.sample
  end

  def choose_hard
    win_position = critical_square?(game_piece)
    block_position = critical_square?(opponent_piece)

    if comp_goes_first?
      1
    elsif second_and_center?
      CENTER
    elsif win_position
      win_position
    elsif block_position
      block_position
    else
      weighted_position
    end
  end

  def comp_goes_first?
    available_spaces.size == 9
  end
  
  def second_and_center?
    available_spaces.size == 8 && available_spaces.include?(CENTER)
  end
  
  def critical_square?(piece)
    win_lines = potential_win_lines_for(piece)
    win_lines.each do |line|
      state = line.map { |position| board.state_of(position) }
      return line[state.index(nil)] if state.count(piece) == 2
    end
    nil
  end
  
  def potential_win_lines_for(piece)
    occupied = positions_containing(piece)

    WIN_LINES.select do |win_line|
      win_line.all? do |position| 
        occupied.include?(position) ||
        board.state_of(position) == nil
      end
    end
  end

  def positions_containing(piece)
    board.all_spaces.select do |position| 
      board.state_of(position) == piece
    end
  end

  def weighted_position
    @positions_occupied = positions_containing(game_piece)
    weights = find_weights
  
    max_index = weights.index(weights.max)
    available_spaces[max_index]
  end
  
  def find_weights
    available_spaces.map do |position|
      weight = 0
      WIN_LINES.each do |line|
        next unless line.include?(position)
        positions_occupied.each do |comp_position|
          weight += 1 if desireable_square?(line, comp_position, position)
        end
      end
      weight
    end
  end

  def desireable_square?(line, comp_position, position)
    line.include?(comp_position) &&
      !line.include?(CENTER) &&
      CORNERS.include?(position)
  end
  
end

class TTTGame
  @@game_number = 0
  @@computer = true
  TITLE = "Tic Tac Toe"
  X = :X
  O = :O
  
  WIN_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9],
              [1, 4, 7], [2, 5, 8], [3, 6, 9],
              [1, 5, 9], [7, 5, 3]]

  include Invalid
  attr_reader :map, :title, :board, :player1, :player2, :order, :winner

  def display_goodbye_message
    puts "Thanks for playing Tic Tac Toe!"
  end

  def display_welcome_message
    puts "Welcome to Tic Tac Toe!"
  end

  def display_opponent_move
    puts "#{order.last} chose position #{last_move}"
  end

  def display_score
    p1_score = format_score(player1.score)
    p2_score = format_score(player2.score)
    span = max_name_size + 2
    scoreboard = build_scoreboard(span, p1_score, p2_score)

    puts scoreboard
  end

  def build_scoreboard(span, p1_score, p2_score)
    line = horizontal_rule(span)
    names = "|" + player1.name.center(span) +
            "|" + player2.name.center(span) + "|"
    scores = "|" + p1_score.center(span) + "|" + p2_score.center(span) + "|"

    <<-SCORE
    #{TITLE.center((span * 2) + 4,'-')}
    #{line}
    #{names}
    #{scores}
    #{line}
    SCORE
  end

  def horizontal_rule(span)
    "+" + "-" * span + "+" + "-" * span + "+"
  end

  def format_score(score)
    score.to_s.rjust(2, '0')
  end

  def max_name_size
    [player1.name.size, player2.name.size].max
  end

  def refresh_screen
    system 'clear'
    display_score
    puts order.first
    puts board
    puts map
  end

  def setup_game
    if @@game_number == 0
      @board = Board.new
      build_players 
    else
      board.reset
      player1.reset
      player2.reset
    end
    
    @map = Map.new
    determine_turn_order
  end

  def build_players
    num_humans = nil
    loop do
      puts "Please enter the number of human players (1 or 2):"
      num_humans = gets.chomp
      %w(1 2).include?(num_humans) ? break : invalid
    end
    
    @@computer = false if num_humans == '2'

    @player1 = Human.new(@board)
    @player2 = @@computer ? Computer.new(@board) : Human.new(@board, "Player 2")
  end

  def determine_turn_order
    @order = @@game_number.even? ? [player1, player2] : [player2, player1]
    order.first.game_piece = X
    order.last.game_piece = O
  end

  def take_turn
    refresh_screen
    current_player = order.first
    position = current_player.choose_position
    board.mark_square(position, current_player.game_piece)
    map.clear(position)
    order.rotate!
  end

  def someone_won?
    winning_mark = winner?
    return false unless winning_mark
    
    @winner = player1.game_piece == winning_mark ? player1 : player2
    winner.increment_score
    @@game_number += 1
  end

  def winner?
    winner = nil

    WIN_LINES.each do |win_line|

      line = win_line.map do |position|
        board.board[position].state
      end

      winner = X if line.all?(X)
      winner = O if line.all?(O)
      break if winner
    end
    winner
  end

  def board_full?
    @board.available_spaces.empty?
  end

  def display_result
    if winner
      puts "#{winner.name} won!"
    else
      puts "It's a draw!"
    end
  end

  def play_again?
    choice = nil
    loop do
      puts "Would you like to play again? (y/n)"
      choice = gets.chomp
      break if ['y', 'n'].include?(choice.downcase)
      puts "Sorry, invalid choice."
    end
    choice == 'y'
  end

  def play
    display_welcome_message
    loop do
      setup_game
      loop do
        take_turn
        break if someone_won? || board_full?
      end
      refresh_screen
      display_result
      break unless play_again?
    end
    display_goodbye_message
  end
end

game = TTTGame.new
game.play