module Invalid
  def invalid
    prompt "Invalid entry, please try again"
  end
end

module Formatting
  attr_reader :span

  def prompt(message)
    puts "==> #{message}"
  end

  def display(message)
    puts "    #{message}"
  end

  def format_score(score)
    score.to_s.rjust(2, '0')
  end

  def heading(title)
    title.center((span * 2) + 4, '-').to_s
  end

  def horizontal_rule
    "+" + "-" * span + "+" + "-" * span + "+"
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

class Grid
  attr_accessor :span
  attr_reader :grid

  def initialize(span)
    @span = span
    build_grid
  end

  def to_s
    indent = " " * (span - 7)
    grid_as_string = <<-GRID
    
    #{indent}     |     |
    #{indent}  #{@grid[1]}  |  #{@grid[2]}  |  #{@grid[3]}
    #{indent}_____|_____|_____
    #{indent}     |     |
    #{indent}  #{@grid[4]}  |  #{@grid[5]}  |  #{@grid[6]}
    #{indent}_____|_____|_____
    #{indent}     |     |
    #{indent}  #{@grid[7]}  |  #{@grid[8]}  |  #{@grid[9]}
    #{indent}     |     |
    
    GRID
    grid_as_string
  end
end

class Map < Grid
  def build_grid
    @grid = Hash.new
    1.upto(9) do |i|
      square = Square.new(i)
      @grid[i] = square
    end
  end

  def clear(position)
    @grid[position].clear
  end
end

class Board < Grid
  @@all_spaces = *(1..9)
  attr_reader :available_spaces

  def initialize(span=0)
    super(span)
    @available_spaces = *(1..9)
  end

  def all_spaces
    @@all_spaces
  end

  def state_of(position)
    grid[position].state
  end

  def build_grid
    @grid = Hash.new
    1.upto(9) do |i|
      square = Square.new
      @grid[i] = square
    end
  end

  def mark_square(position, game_piece)
    @grid[position].mark(game_piece)
    available_spaces.delete(position)
  end

  def reset
    @available_spaces = *(1..9)
    build_grid
  end
end

class Player
  attr_accessor :game_piece
  attr_reader :score, :name, :board, :available_spaces

  include Formatting

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
    " " * 4 + "#{name}'s turn, you are #{game_piece}'s!"
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
      prompt "Please enter #{label}'s name: "
      chosen_name = gets.chomp

      break unless chosen_name.empty?
      prompt "Name cannot be blank"
    end
    @name = chosen_name
  end

  def choose_position
    prompt_for_position
  end

  def prompt_for_position
    loop do
      prompt "Choose a square (#{joinor(available_spaces)}): "
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
      prompt "Invalid choice, please enter a number from the available spaces"
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
  attr_reader :difficulty, :opponent_piece, :potential_win_lines,
              :win_position, :block_position

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
      prompt "Please select a difficulty - Easy(e) or Hard(h): "
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

  def to_s
    " " * 4 + "#{name} is thinking..."
  end

  def choose_position
    sleep(rand(1..2))
    if difficulty == :easy
      choose_easy
    else
      return 1 if comp_goes_first?
      return CENTER if second_and_center?
      @win_position = critical_square?(game_piece)
      @block_position = critical_square?(opponent_piece)
      choose_hard
    end
  end

  def choose_easy
    available_spaces.sample
  end

  def choose_hard
    if win_position
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
          board.state_of(position).nil?
      end
    end
  end

  def positions_containing(piece)
    board.all_spaces.select do |position|
      board.state_of(position) == piece
    end
  end

  def weighted_position
    @potential_win_lines = potential_win_lines_for(game_piece)
    weights = find_weights

    max_index = weights.index(weights.max)
    available_spaces[max_index]
  end

  def find_weights
    available_spaces.map do |position|
      weight = 0
      WIN_LINES.each do |line|
        next unless line.include?(position)
        weight += 1 if desireable_square?(line, position)
      end
      weight
    end
  end

  def desireable_square?(line, position)
    potential_win_lines.include?(line) &&
      !line.include?(CENTER) &&
      CORNERS.include?(position)
  end
end

class TTTGame
  TITLE = "Tic Tac Toe"
  X = :X
  O = :O

  WIN_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9],
               [1, 4, 7], [2, 5, 8], [3, 6, 9],
               [1, 5, 9], [7, 5, 3]]

  include Invalid
  include Formatting
  attr_reader :map, :board, :player1, :player2, :order, :winner, :span
  attr_accessor :game_number, :game_over, :computer

  def initialize
    @span = 0
    @game_number = 0
    @computer = true
  end

  def display_welcome_message
    puts "Welcome to Tic Tac Toe!"
  end

  def display_goodbye_message
    puts "Thanks for playing Tic Tac Toe!"
  end

  def display_scoreboard
    scoreboard = build_scoreboard
    puts scoreboard
  end

  def name_of(player)
    player.name.center(span)
  end

  def score_of(player)
    score = format_score(player.score)
    score.center(span)
  end

  def build_scoreboard
    line = horizontal_rule
    names = "|#{name_of(player1)}|#{name_of(player2)}|"
    scores = "|#{score_of(player1)}|#{score_of(player2)}|"

    <<-SCOREBOARD
    #{heading(TITLE)}
    #{line}
    #{names}
    #{scores}
    #{line}
    SCOREBOARD
  end

  def max_name_size
    [player1.name.size, player2.name.size].max
  end

  def refresh_screen
    system 'clear'
    display_scoreboard
    puts order.first unless game_over
    puts board
    display heading("Map")
    puts map
  end

  def reset_game
    board.reset
    player1.reset
    player2.reset
  end

  def setup_game
    if game_number == 0
      @board = Board.new
      build_players
    else
      reset_game
    end

    @game_over = false
    @map = Map.new(span)
    determine_turn_order
  end

  def prompt_for_num_humans
    num_humans = nil
    loop do
      prompt "Please enter the number of human players (1 or 2):"
      num_humans = gets.chomp
      %w(1 2).include?(num_humans) ? break : invalid
    end
    num_humans
  end

  def build_players
    num_humans = prompt_for_num_humans
    @computer = false if num_humans == '2'

    @player1 = Human.new(@board)
    @player2 = computer ? Computer.new(@board) : Human.new(@board, "Player 2")

    @span = max_name_size + 2
    board.span = span
  end

  def determine_turn_order
    @order = game_number.even? ? [player1, player2] : [player2, player1]
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
    true
  end

  def winner?
    @winner = nil

    WIN_LINES.each do |win_line|
      line = win_line.map do |position|
        board.grid[position].state
      end

      @winner = X if line.all?(X)
      @winner = O if line.all?(O)
      break if winner
    end
    winner
  end

  def board_full?
    @board.available_spaces.empty?
  end

  def finish_game
    @game_over = true
    @game_number += 1
    refresh_screen
    if winner
      display "#{winner.name} won!"
    else
      display "It's a draw!"
    end
  end

  def play_again?
    choice = nil
    loop do
      prompt "Would you like to play again? (y/n)"
      choice = gets.chomp.downcase
      break if %w(y n yes no).include?(choice)
      invalid
    end
    choice == 'y' || choice == 'yes'
  end

  def play_game
    loop do
      take_turn
      break if someone_won? || board_full?
    end
  end

  def play
    display_welcome_message
    loop do
      setup_game
      play_game
      finish_game
      break unless play_again?
    end
    display_goodbye_message
  end
end

game = TTTGame.new
game.play
