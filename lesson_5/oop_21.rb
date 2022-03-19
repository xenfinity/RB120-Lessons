class Player
  HIT = :hit
  STAY = :stay
  DECISIONS = [HIT, STAY]

  attr_reader :hand

  def initialize
    @hand = []
  end

  def add_to_hand(card)
    @hand << card
  end

  

  def busted?
  end

  def total
    
  end
end

class Human < Player
  def make_decision
    
  end
end

class Computer < Player
  def make_decision
    DECISIONS.sample
  end
end

class Dealer < Computer
  def deal
    
  end
end

class Deck
  attr_accessor :cards

  def initialize(num_of_decks = 1)
    @cards = []
    create_deck(num_of_decks)
    shuffle_deck
  end

  def create_deck(num_of_decks)
    num_of_decks.times do 
      Card::SUITS.each do |suit|
        Card::FACES.each do |face|
          @cards << Card.new(suit, face)
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

end

class Display
  SUIT_SYMBOL = {
    "H" => "\u2665".encode('utf-8'),
    "D" => "\u2666".encode('utf-8'),
    "C" => "\u2663".encode('utf-8'),
    "S" => "\u2660".encode('utf-8')
  }

  def hand(player_hand)
    card_strings = player_hand.map do |card| 
                     card_to_s(card.face, card.suit)
                   end

    hand_string = hand_to_s(card_strings)
    puts hand_string
  end
  
  private

  def hand_to_s(card_strings)
    hand_string = ""
    0.upto(6) do |line_number|
      hand_string_line = ""
      hand.each do |card_string|
        lines = card_string.lines
        hand_string_line << lines[line_number].chomp
      end
      hand_string << hand_string_line + "\n"
    end
    hand_string
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
  def play
    display = Display.new
    deck = Deck.new
    card1 = Card.new("K", "D")
    card2 = Card.new("A", "S")
    card3 = Card.new("10", "C")

    hand = [card1, card2, card3]

    display.hand(hand)
  end
end

TwentyOneGame.new.play