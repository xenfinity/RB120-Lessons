# Create a class called MyCar. When you initialize a new instance or object of the class, allow the user 
# to define some instance variables that tell us the year, color, and model of the car. Create an instance 
# variable that is set to 0 during instantiation of the object to track the current speed of the car as well. 
# Create instance methods that allow the car to speed up, brake, and shut the car off.

class MyCar
  attr_accessor :colour, :speed, :on
  attr_reader :model, :year

  def initialize(year, colour, model)
    @year = year
    @colour = colour
    @model = model
    @on = false
    @speed = 0
  end

  def speed_up(number)
    if on
      self.speed += number
      puts "Speeding up"
      puts "Current speed - #{speed}"
    else
      puts "Please turn the car on before accelerating"
    end
  end

  def brake(number)

    if speed == 0
      puts "Braking did nothing"
    elsif (speed - number) < 0
      self.speed = 0
      puts "Braking"
    else
      self.speed -= number
      puts "Braking"
    end
    puts "Current speed - #{speed}"
  end

  def spray_paint (new_colour)
    self.colour = new_colour
    puts "#{year} #{model} is now #{colour}"
  end 

  def turn_off
    self.speed = 0
    self.on = false
    puts "Current speed - #{speed}"
    puts "Car is now off"
  end

  def turn_on
    self.on = true
    puts "Car is now on!"
  end
end

golfy = MyCar.new(2015, "Black", "Golf")

# golfy.turn_on
golfy.speed_up(100)
golfy.brake(20)
golfy.brake(30)
golfy.brake(60)
golfy.spray_paint("White")
golfy.turn_off