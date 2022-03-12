
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

  attr_reader :board, :available_spaces

  def initialize
    @available_spaces = *(1..9)
    build_board
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
    @available_spaces = board.available_spaces
    choose_name
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
  WIN_STATES = [[1, 2, 3], [4, 5, 6], [7, 8, 9],
              [1, 4, 7], [2, 5, 8], [3, 6, 9],
              [1, 5, 9], [7, 5, 3]]
  DIFFICULTIES = {
    'e' => :easy,
    'easy' => :easy,
    'h' => :hard,
    'hard' => :hard
  }

  include Invalid
  attr_reader :difficulty
  
  def initialize(board)
    super
    select_difficulty
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
    if comp_goes_first?
      1
    elsif second_and_center?
      CENTER
    elsif win_line
      win_line
    elsif block_line
      block_line
    else
      weighted_line(board, comp, choices, lines.first)
    end
  end

  def comp_goes_first?
    available_spaces.size == 9
  end
  
  def second_and_center?
    available_spaces.size == 8 && available_spaces.include?(CENTER)
  end
  
  def critical_square?
    lines = split_win_states

    lines.each do |line|
      state = line.map { |sq| board[sq] }
      next unless state.any?(EMPTY)
      return line[state.index(EMPTY)] if state.count(mark) == 2
    end
    nil
  end
  
  def split_win_states(board, opp)
    opp_squares = board.keys.select { |sq| board[sq] == opp }
    WIN_STATES.partition do |state|
      state.any? { |sq| opp_squares.include?(sq) }
    end.reverse
  end
  
  def desireable_square?(line, cmp_sq, sq)
    line.include?(cmp_sq) &&
      !line.include?(CENTER) &&
      CORNERS.include?(sq)
  end
  
  def state(board, opp, comp)
    choices = find_choices(board)
    lines = split_win_states(board, opp)
    win_line = critical_square?(board, lines.first, comp)
    block_line = critical_square?(board, lines.last, opp)
  
    [choices, lines, win_line, block_line]
  end
  
  def find_weights(choices, win_lines, comp_squares)
    choices.map do |sq|
      weight = 0
      win_lines.each do |line|
        next unless line.include?(sq)
        comp_squares.each do |cmp_sq|
          weight += 1 if desireable_square?(line, cmp_sq, sq)
        end
      end
      weight
    end
  end
  
  def weighted_line(board, comp, choices, win_lines)
    comp_squares = board.keys.select { |sq| board[sq] == comp }
    weights = find_weights(choices, win_lines, comp_squares)
  
    max_index = weights.index(weights.max)
    choices[max_index]
  end

end

class TTTGame
  @@game_number = 0
  @@computer = true
  TITLE = "-------Tic Tac Toe-------"
  X = :X
  O = :O
  WIN_STATES = [[1, 2, 3], [4, 5, 6], [7, 8, 9],
              [1, 4, 7], [2, 5, 8], [3, 6, 9],
              [1, 5, 9], [7, 5, 3]]

  include Invalid
  attr_reader :map, :title, :board, :player1, :player2, :order, :winner

  def initialize
    @map = Map.new
  end

  def display_goodbye_message
    puts "Thanks for playing Tic Tac Toe!"
  end

  def display_welcome_message
    puts "Welcome to Tic Tac Toe!"
  end

  def display_opponent_move
    puts "#{order.last} chose position #{last_move}"
  end

  def refresh_screen
    system 'clear'
    puts TITLE
    puts order.first
    puts board
    puts map
  end

  def setup_game
    @board = Board.new
    build_players if @@game_number == 0
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
  end

  def winner?
    winner = nil

    WIN_STATES.each do |win_line|

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

  def play
    display_welcome_message
    setup_game
    loop do
      take_turn
      break if someone_won? || board_full?
    end
    refresh_screen
    display_result
    display_goodbye_message
  end
end

game = TTTGame.new
game.play