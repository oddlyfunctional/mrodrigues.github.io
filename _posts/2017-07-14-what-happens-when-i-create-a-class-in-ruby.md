---
layout: post
title: "What happens when I create a class in Ruby?"
description: 
headline: 
modified: 2017-07-14 10:26:20 -0300
category: programming
tags: [ruby]
imagefeature: 
mathjax: 
chart: 
comments: true
featured: false
---

That Ruby is strongly object-oriented is common knowledge. Everything is an object, from integers to the `nil` value. But what does that mean exactly? If everything is an object, what is the class of a *class*?

Let's review for a moment the well-known syntax for creating a class:

```ruby
class Person
end

puts Person.class.inspect # => Class
```

Ok, now that's interesting. And what about the class of the `Class` class (I swear I'm not being confusing on purpose)?

```ruby
puts Class.class.inspect # => Class

# Wait, so that means?...

puts Class.class.class.inspect # => Class

# Hmmm...
puts Class.class.class.class.inspect # => Class

# Yup. Alright, I'm done going down that rabbit hole. For today.
```

So if a `Class` is an instance of a `Class`, what happens if I instantiate a new `Class`?

```ruby
klass = Class.new
puts klass.inspect # => #<Class:0x000000030714c8>
puts klass.new.inspect # => #<#<Class:0x000000030714c8>:0x0000000303b800>
```

That looks like the inspect of an instance! Does this mean that the inverse also works?

```ruby
class klass; end # => SyntaxError: (eval):2: class/module name must be CONSTANT
```

Nope, it seems that the `class` syntax requires the name of the class to be a constant. Did you notice that the output of the variable `klass` when containing an instance of `Class` is very different than the ones we're used to? That's also related to constants:

```ruby
Person = Class.new
puts Person.inspect # => Person
puts Person.new.inspect # => #<Person:0x00000002f71f50>
```

It seems that the inspect method has a special case for constants. Now that explains a lot! That's why when I forget to require some library or mistype a class I get this error:

```ruby
puts Persno.inspect # => NameError: uninitialized constant Persno
```

When requiring a file, unless a namespace is defined, its constants are declared in the uppermost scope (which is `Object` btw), *and that is why I'm able to access the class name independently of the scope I'm in*:

```ruby
# Accessing the class through the constant
def create_person
  Person.new
end

puts create_person.inspect # => #<Person:0x00000002dcd960>

# As opposed to receiving the class as an argument (since local
# variables aren't visible outside of its local scope):
def create_person(person_klass)
  person_klass.new
end

puts create_person(klass).inspect # => #<#<Class:0x000000030714c8>:0x00000002c8ef68>

# This also works btw:
puts create_person(Person).inspect # => #<Person:0x00000002bcf618>
```

Did you notice when I said that the uppermost scope is `Object`? That has repercussions that may not be obvious at the first glance:

```ruby
# Try opening IRB and typing this:
puts self.inspect # => main
puts self.class.inspect # => Object

# So does that mean...
A_CONSTANT = 1
puts Object::A_CONSTANT.inspect # => 1

Object::ANOTHER_CONSTANT = 2
puts ANOTHER_CONSTANT.inspect # => 2

# And that...
class Person
end

puts Object::Person.inspect # => Person

# And since self is an instance of Object:
puts self.class::Person.inspect # => Person
```

Since everything in Ruby *is* an object, meaning that it is a *descendant* of `Object`, any constants (or methods for that matter) declared in its scope are available *everywhere*. That's awesome and explains so much!

Ok, we've been far enough that you must be wondering how does one define methods when instantiating a `Class`:

```ruby
Person = Class.new do
  def say_hi
    puts "Hi"
  end
end

Person.new.say_hi # => Hi
```

If you've been following closely you may be trying to figure out how does inheritance fits into all of this:

```ruby
Person = Class.new do
  def say_hi
    puts "Hi"
  end
end

Employee = Class.new(Person) do
  def say_bye
    puts "Bye"
  end
end

Employee.new.say_hi # => Hi
Employee.new.say_bye # => Bye
```

Great! That means that we can now completely ditch the old boring way of creating classes and use this! Should we? Of course not, it'll only make you look like a smartass (like I must probably look right now), but it's cool anyway:

```ruby
Employee = Class.new(Person) do
  attr_accessor :salary

  def initialize(salary)
    @salary = salary
  end
end

puts Employee.new(1234).salary.inspect # => 1234
```

And if that's the case, the `self` inside the block must be...

```ruby
klass = nil
Person = Class.new do
  klass = self
end

puts (Person == klass).inspect # => true
```

That's it for today folks, I think I exhausted everything that I could on this topic (aside from that damn `Class.class.class.class`... I'm certainly getting back to that someday). I love how Ruby seems to make perfect internal logic, like a well-written novel! Each and every piece of syntax can be simplified and eventually reduced to instantiating objects and calling methods, differently than languages like Java where some things simply... are the way they are.

Know other interesting quirks of the Ruby language? Did I make a mistake or made no sense at all? Send me a message and let me know! :)
