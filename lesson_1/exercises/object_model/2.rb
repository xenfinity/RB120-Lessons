# What is a module? What is its purpose? How do we use them with our classes? 
# Create a module for the class you created in exercise 1 and include it properly.
=begin
A module is a definition of functionality that can be included in multiple classes. We use them by 'include'ing them at the beginning 
of our class definition and then calling the method(s) defined in the module on the instance of the class
=end

module Bark
  def bark
    puts "WOOF"
  end
end


class Mammal
  include Bark
end

dog = Mammal.new
dog.bark
