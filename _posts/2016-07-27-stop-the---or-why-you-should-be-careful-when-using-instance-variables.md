---
layout: post
title: "Stop the @! (or why you should be careful when using instance variables)"
description: 
headline: 
modified: 2016-07-27 13:23:33 -0300
category: personal
tags: [ruby]
imagefeature: 
mathjax: 
chart: 
comments: true
featured: false
---

Ruby is great, but once in a while I question some decisions in its design. Instance variables is one of them: the fact that virtually any instance variable "exists" at any time and its default value is `nil` leads to extremely common errors. Surely, I can understand their reasons, after all Ruby prides itself as being optimized for programmer happiness, and boilerplate is the opposite of happiness. That said, consider the following example:

```ruby
class Post
  attr_reader :comments

  def initialize
    @coments = []
  end
end

Post.new.comments << value
```

BOOM! You got a `NoMethodError: undefined method '<<' for nil:NilClass`! Did you notice the problem? After a typo, I accidentally assigned the array to the `@coments` instance variable, leaving the `@comments` with the `nil` value. "Oh, but you should always test your code, so this is a non-problem, and is so easy to track this error down" you must be thinking. Hold that thought for a second and consider the case when we have collaborators involved:

```ruby
class Post
  def initialize
    @mention_finder = MentionFinder.new
    @coments = []
  end

  def mentions
    @mention_finder.mentions(@comments)
  end
end
```

It's perfectly possible that the collaborator uses the list much later down the road, even passing it down again to other collaborators of its own. It can be worse: the value can be passed not from inside the class, but from an external mediator. It's even possible that that value is only used in some forgotten edge case. In any case, when it's finally used, the error will blow up in a place that doesn't have anything to do with where the `nil` was originated.

This is a kind of error that's difficult to debug, since we need to re-construct the call stack and figure out in which step we messed up. Of course, Ruby is a language that contain null values and that's going to stay, this kind of errors will always exist (the null value creator even [apologized for inventing it](https://en.wikipedia.org/wiki/Tony_Hoare#Apologies_and_retractions)), but there's better ways. I could go on and on talking about how to avoid them with different techniques, such as [null objects](https://en.wikipedia.org/wiki/Null_Object_pattern) and [maybe monads](https://en.wikipedia.org/wiki/Monad_(functional_programming)#The_Maybe_monad), but here I want to focus on this mundane mistake and a simple, achievable technique to avoid it: methods. This is an alternative implementation:

```ruby
class Post
  attr_accessor :mention_finder, :comments

  def initialize
    self.mention_finder = MentionFinder.new
    self.coments = []
  end

  def mentions
    mention_finder.mentions(comments)
  end
end
```

At any point, if we screw up, Ruby's interpreter will let us know: `NameError: undefined local variable or method 'coments' for #<Post:0x000000025e6120>`. Oh, the beauties of failing early! Now we know exactly where we made the mistake! "But I don't want to pollute my external API with those internal matters!" you're probably thinking. And you're right, we don't want that. That's why I use **private attribute accessors**:

```ruby
class Post
  def initialize
    self.mention_finder = MentionFinder.new
    self.coments = []
  end

  def mentions
    mention_finder.mentions(comments)
  end

  private
    attr_accessor :mention_finder, :comments
end
```

Just a little boilerplate and we're both protected from typos and exposing only what we need.

One thing that I also like to do whenever I need to initialize my instance variables with some constant, be that constant a literal or an instance of a user-made class -- something that doesn't contain any input and therefore is always going to return the same value no matter when it's called (though of course that's not really 100% true since we're in a language filled with state) --, is performing a lazy initialization:

```ruby
class Post
  def mentions
    mention_finder.mentions(comments)
  end

  private

    def mention_finder
      @mention_finder ||= MentionFinder.new
    end

    def comments
      @comments ||= []
    end
end
```

I like this style particularly when the instance variables I'm creating are never going to be re-assigned (although they can change their state via message-sending). It's easy to reason about this code: those methods are going to return some non-null value -- always. It doesn't depend on another part of the code to initialize the value its instance variable contains; it is, therefore, independent from context and order of call.

Null values are annoying rocks in our developer shoes, but with some ground rules they are much easier to manage. Fail fast, fail early, and make errors obvious; your code will be much easier to maintain that way.
