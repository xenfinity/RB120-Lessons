module DisplayUtilities
  def invalid
    prompt "Invalid entry, please try again"
  end

  def clear
    system 'clear'
  end

  def pause
    sleep(rand(1..2))
  end
end

module Formatting
  attr_reader :span

  def prompt(message)
    puts "==> #{message}"
  end

  def indent(message)
    "    #{message}"
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

  def joinor(items, delim=', ', tail='or')
    return items[-1].to_s if items.size == 1
    items[0...-1].join(delim) +
      ' ' + tail + ' ' +
      items[-1].to_s
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

class Board < Grid
  X = :X
  O = :O
  CORNERS = [1, 3, 7, 9]
  CENTER = 5
  WIN_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9],
               [1, 4, 7], [2, 5, 8], [3, 6, 9],
               [1, 5, 9], [7, 5, 3]]
  OPP_PIECE = {
    X: O,
    O: X
  }

  @@all_spaces = *(1..9)
  attr_reader :available_spaces

  def initialize(span=0)
    super(span)
    @available_spaces = *(1..9)
  end

  def all_spaces
    @@all_spaces
  end

  def [](position)
    grid[position].state
  end

  def []=(position, piece)
    @grid[position].mark(piece)
    available_spaces.delete(position)
  end

  def winner?
    winner = nil

    WIN_LINES.each do |win_line|
      line_state = win_line.map do |position|
        self[position]
      end

      winner = X if line_state.all?(X)
      winner = O if line_state.all?(O)
      break if winner
    end

    winner
  end

  def reset
    @available_spaces = *(1..9)
    build_grid
  end

  private

  def build_grid
    @grid = Hash.new
    1.upto(9) do |i|
      square = Square.new
      @grid[i] = square
    end
  end
end

class Map < Grid
  def clear(position)
    @grid[position].clear
  end

  private

  def build_grid
    @grid = Hash.new
    1.upto(9) do |i|
      square = Square.new(i)
      @grid[i] = square
    end
  end
end

class Player
  attr_accessor :ttt_piece
  attr_reader :score, :name, :board, :available_spaces

  include Formatting
  include DisplayUtilities

  def initialize(board)
    @board = board
    @score = 0
    choose_name
    @available_spaces = board.available_spaces
  end

  def new_game
    @available_spaces = board.available_spaces
  end

  def to_s
    indent "#{name}'s turn, you are #{ttt_piece}'s!"
  end

  def increment_score
    @score += 1
  end

  def <=>(other_player)
    score <=> other_player.score
  end
end

class Human < Player
  attr_reader :label

  def initialize(board, label="Player 1")
    @label = label
    super(board)
  end

  def choose_position(available_spaces)
    @available_spaces = available_spaces
    prompt_for_position
  end

  private

  def choose_name
    chosen_name = nil
    loop do
      prompt "Please enter #{label}'s name: "
      chosen_name = gets.chomp

      break unless chosen_name.empty?
      invalid
    end
    @name = chosen_name
  end

  def prompt_for_position
    loop do
      prompt "Choose a square (#{joinor(available_spaces)}): "
      input = gets.chomp

      return input.to_i if valid_space_choice?(input)
      invalid
    end
  end

  def valid_space_choice?(input)
    unless input == input.to_i.to_s && available_spaces.include?(input.to_i)
      return false
    end
    true
  end
end

class Computer < Player
  DIFFICULTIES = {
    'e' => :easy,
    'easy' => :easy,
    'h' => :hard,
    'hard' => :hard
  }

  include DisplayUtilities
  attr_reader :difficulty, :opponent_piece, :potential_win_lines,
              :win_position, :block_position

  def initialize(board)
    super
    select_difficulty
  end

  def ttt_piece=(piece)
    @ttt_piece = piece
    @opponent_piece = Board::OPP_PIECE[piece]
  end

  def choose_position(available_spaces)
    @available_spaces = available_spaces
    pause
    if difficulty == :easy
      choose_easy
    else
      return 1 if comp_goes_first?
      return Board::CENTER if second_and_center?
      choose_hard
    end
  end

  private

  def select_difficulty
    choice = nil
    loop do
      prompt "Please select a difficulty - Easy(e) or Hard(h): "
      choice = gets.chomp.downcase

      break if %w(e h easy hard).include?(choice)
      invalid
    end
    @difficulty = DIFFICULTIES[choice]
  end

  def choose_name
    @name = ["Magic Head", "Galileo Humpkins",
             "Hollabackatcha", "Methuselah Honeysuckle"].sample
  end

  def to_s
    indent "#{name} is thinking..."
  end

  def choose_easy
    available_spaces.sample
  end

  def choose_hard
    @win_position = critical_square?(ttt_piece)
    @block_position = critical_square?(opponent_piece)
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
    available_spaces.size == 8 && available_spaces.include?(Board::CENTER)
  end

  def critical_square?(piece)
    win_lines = potential_win_lines_for(piece)
    win_lines.each do |line|
      state = line.map { |position| board[position] }
      return line[state.index(nil)] if state.count(piece) == 2
    end
    nil
  end

  def potential_win_lines_for(piece)
    occupied = positions_containing(piece)

    Board::WIN_LINES.select do |win_line|
      win_line.all? do |position|
        occupied.include?(position) ||
          board[position].nil?
      end
    end
  end

  def positions_containing(piece)
    board.all_spaces.select do |position|
      board[position] == piece
    end
  end

  def weighted_position
    @potential_win_lines = potential_win_lines_for(ttt_piece)
    weights = find_weights

    max_index = weights.index(weights.max)
    available_spaces[max_index]
  end

  def find_weights
    available_spaces.map do |position|
      weight = 0
      Board::WIN_LINES.each do |line|
        next unless line.include?(position)
        weight += 1 if desireable_square?(line, position)
      end
      weight
    end
  end

  def desireable_square?(line, position)
    potential_win_lines.include?(line) &&
      !line.include?(Board::CENTER) &&
      Board::CORNERS.include?(position)
  end
end

class TTTGame
  TITLE = "Tic Tac Toe"

  include DisplayUtilities
  include Formatting
  attr_reader :map, :board, :max_score, :player1, :player2,
              :order, :winner, :champion
  attr_accessor :game_number, :game_over, :computer

  def initialize
    @span = 0
    @game_number = 0
    @computer = true
    @champion = nil
  end

  def play
    display_welcome_message
    loop do
      setup_game
      play_game
      finish_game
      break if max_score_reached? || !play_again?
    end
    set_champion
    display_goodbye_message
  end

  private

  def display_welcome_message
    puts "Welcome to Tic Tac Toe!"
  end

  def display_goodbye_message
    if champion
      puts "#{champion.name} is the champion!"
    else
      puts "It's a tie! Everyone is a champion!"
    end
    puts "Thanks for playing Tic Tac Toe!"
  end

  def setup_game
    if game_number == 0
      @board = Board.new
      build_players
      set_max_score
    else
      board.reset
    end

    @game_over = false
    @map = Map.new(span)
    determine_turn_order
  end

  def set_max_score
    max_score = nil
    loop do
      prompt "Please enter a maximum score (number greater than 4): "
      max_score = gets.chomp
      valid_max_score?(max_score) ? break : invalid
    end
    @max_score = max_score.to_i
  end

  def valid_max_score?(num)
    if num.to_i.to_s == num && num != '0' &&
       num.to_i >= 5
      return true
    end
    false
  end

  def build_players
    num_humans = prompt_for_num_humans
    @computer = false if num_humans == '2'

    @player1 = Human.new(@board)
    @player2 = computer ? Computer.new(@board) : Human.new(@board, "Player 2")

    @span = [(max_name_size + 2), 12].max
    board.span = span
  end

  def max_name_size
    [player1.name.size, player2.name.size].max
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

  def determine_turn_order
    @order = game_number.even? ? [player1, player2] : [player2, player1]
    order.first.ttt_piece = Board::X
    order.last.ttt_piece = Board::O
  end

  def refresh_screen
    clear
    display_scoreboard
    puts order.first unless game_over
    puts board
    puts indent(heading("Map"))
    puts map
  end

  def display_scoreboard
    scoreboard = build_scoreboard
    puts scoreboard
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

  def name_of(player)
    player.name.center(span)
  end

  def score_of(player)
    score = format_score(player.score)
    score.center(span)
  end

  def play_game
    loop do
      take_turn
      break if someone_won? || board_full?
    end
  end

  def take_turn
    refresh_screen
    current_player = order.first
    position = current_player.choose_position(board.available_spaces)
    board[position] = current_player.ttt_piece
    map.clear(position)
    order.rotate!
  end

  def someone_won?
    winning_piece = board.winner?
    return false unless winning_piece

    @winner = player1.ttt_piece == winning_piece ? player1 : player2
    winner.increment_score
    true
  end

  def board_full?
    @board.available_spaces.empty?
  end

  def finish_game
    @game_over = true
    @game_number += 1
    refresh_screen
    if winner
      puts indent("#{winner.name} won!")
    else
      puts indent("It's a draw!")
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

  def set_champion
    comparison = player1 <=> player2
    @champion = case comparison
                when 1  then player1
                when -1 then player2
                end
  end

  def max_score_reached?
    [player1.score, player2.score].max >= max_score
  end
end

game = TTTGame.new
game.play
