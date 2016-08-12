---
layout: post
title: "The poor, misunderstood decorator"
description: 
headline: 
modified: 2016-08-12 12:16:48 -0300
category: personal
tags: [design patterns, decorator, ruby]
imagefeature: "covers/colorful-nesting-matryoshka-dolls.jpg"
mathjax: 
chart: 
comments: true
featured: false
---

This is an old pet peeve of mine: again and again I see people failing to grasp what a decorator is. I don’t have any data to back me up here, but I would say that it is the most misunderstood design pattern of all. I’ve seen it being abused by several communities, including my beloved Ruby, in ways that not only change its specification, but defeat completely its purpose. Here’s how the usual "decorator" goes:

```ruby
class UserDecorator
  def initialize(user)
    @user = user
  end

  def email
    @user.email
  end

  def full_name
    "#{@user.first_name} #{@user.last_name}"
  end

  def full_address
    "#{@user.address.number} #{@user.address.street}, #{@user.address.city}, #{@user.address.state}"
  end
end

User = Struct.new(:first_name, :last_name, :email, :address)
Address = Struct.new(:number, :street, :city, :state)

user_decorator =  UserDecorator.new(
                    User.new(
                      "Oddly",
                      "Functional",
                      "hi@oddlyfunctional.com",
                      Address.new("123", "St. Nowhere", "New York", "NY")
                    )
                  )

user_decorator.email
# => "hi@oddlyfunctional.com" 

user_decorator.full_name
# => "Oddly Functional" 

user_decorator.full_address
# => "123 St. Nowhere, New York, NY" 
```

As it is commonly known, a decorator is a presentational component that wraps a model instance and exposes proper methods for presentational purposes (for example, formatting the full address or the full name, while delegating the methods that are not going to be changed to the wrapped instance, as is the case for the email). I say, with a dash of irritation, that this is *not* a decorator. You could call it a presenter or something else, but its goal and usage are completely distinct from a decorator's. This misconception is reinforced by the community as gems (yeah, I'm looking at you, [Draper](https://github.com/drapergem/draper) 👀), and results in fewer and fewer developers knowing what a decorator really is.

But what is it after all?

For a formal definition, you can check the original Gang of Four's [Design Patterns](https://www.amazon.com/Design-Patterns-Elements-Reusable-Object-Oriented-ebook/dp/B000SEIBB8) book, but put simply, a decorator is a class that wraps an instance and implements a well defined interface common to that instance, in order to dynamically and transparently add behaviour to the wrapped instance in a composable manner. "LOL, you look like my teacher, easier said than done" you must be thinking. It's actually really simple and practical. Buckle up, I'm going to show you some code!

```ruby
# I'm using Forwardable, a standard lib module, to make it easier to delegate
# methods that don't change to their original implementation.
# Check its documentation at:
# http://ruby-doc.org/stdlib-2.3.1/libdoc/forwardable/rdoc/Forwardable.html
require 'forwardable'

class UserContactEmailDecorator
  extend Forwardable
  def_delegators :@user, :first_name, :last_name

  def initialize(user)
    @user = user
  end

  def email
    "#{full_name} <#{@user.email}>"
  end

  private

    def full_name
      "#{@user.first_name} #{@user.last_name}"
    end
end

class UserUppercaseNamesDecorator
  extend Forwardable
  def_delegators :@user, :email

  def initialize(user)
    @user = user
  end

  def first_name
    @user.first_name.upcase
  end

  def last_name
    @user.last_name.upcase
  end
end

# I'm leaving the address out since I'm not gonna use it in this example
User = Struct.new(:first_name, :last_name, :email) 
user = User.new("Oddly", "Functional", "hi@oddlyfunctional.com")


# We can compose the decorators as we want
decorated_user = UserContactEmailDecorator.new(UserUppercaseNamesDecorator.new(user))

decorated_user.email
# => "ODDLY FUNCTIONAL <hi@oddlyfunctional.com>"

decorated_user.first_name
# => "ODDLY"

decorated_user.last_name
# => "FUNCTIONAL"


# You probably guessed that the order matters
decorated_user = UserUppercaseNamesDecorator.new(UserContactEmailDecorator.new(user))

decorated_user.email
# => "Oddly Functional <hi@oddlyfunctional.com>" # Different!

decorated_user.first_name
# => "ODDLY"

decorated_user.last_name
# => "FUNCTIONAL"


# We can also use them separately
decorated_user = UserContactEmailDecorator.new(user)
decorated_user.email
# => "Oddly Functional <hi@oddlyfunctional.com>"

decorated_user.first_name
# => "Oddly"

decorated_user.last_name
# => "Functional"


decorated_user = UserUppercaseNamesDecorator.new(user)
decorated_user.first_name
# => "ODDLY"

decorated_user.last_name
# => "FUNCTIONAL"

decorated_user.email
# => "hi@oddlyfunctional.com"
```

Differently from the previous, erroneously called decorator, actual decorators allow the programmer to compose arbitrary behaviours at runtime, benefiting from the indirection of not knowing which class is being received, and having the confidence that any instance of any decorator *and* of the original class will implement to the same common interface. It allows indefinitely nesting, which is kind of awesome ([rack](https://github.com/rack/rack), anyone?). That's impossible to achieve when changing the interface by adding or removing methods, since the client class or the caller wouldn't be able to treat any potentially decorated instance as a member of the defined common interface.

While these examples still implement different ways to present the model, there's nothing in the decorator pattern that makes any reference to how the class is going to be used. To prove that, here follows a use case that doesn't involve a presentational context:

```ruby
class Operator
  def run
    # Do something
  end
end

class OperationLoggerDecorator
  def initialize(operator, logger)
    @operator = operator

    # An important point to note is that having the same interface
    # doesn't mean having the same constructor. Whichever client code
    # that's instantiating the decorator *knows* what it's doing.
    @logger = logger
  end

  def run
    @logger.info "Initiating operation..."
    result = @operator.run
    @logger.info "Finished with result: #{result}"

    result # Returning the result to be used by the client
  end
end

class OperationNotifierDecorator
  def initialize(operator)
    @operator = operator
  end

  def run
    result = @operator.run
    Notification.create("Operation finished with result: #{result}")

    result
  end
end

# I can freely compose the decorators!
operator = Operator.new
operator.run

OperationLoggerDecorator.new(operator).run
OperationNotifierDecorator.new(operator).run

OperationLoggerDecorator.new(OperationNotifierDecorator.new(operator)).run
OperationNotifierDecorator.new(OperationLoggerDecorator.new(operator)).run


# Or, in a more realistic manner:
Settings = Struct.new(:log?, :notify?)

# In a real application, the settings would be
# stored somewhere, probably in the database.
settings = Settings.new(true, true)

if settings.log?
  operator = OperationLoggerDecorator.new(operator)
end

if settings.notify?
  operator = OperationNotifierDecorator.new(operator)
end

operator.run
```

Phew, this is a weight off my shoulders! I've been annoyed by this common misconception for so long, but never took the time to write about it. It feels so fine it's almost therapeutic!

I hope you can now appreciate decorators for what they really are. You could argue that they lead to too much indirection or that they are overkill solutions for simple cases (and you probably would be right). You have the right not to like it and decide not to use it. But please, **please**, don't call a presenter a decorator.

*I must add an addendum and say that I don't hate presenters. They are a great way to manage certain complexities and avoid bloating your views, but names and definitions are important.*
