---
layout: post
title: "What are Rails helpers good for, anyway?"
description: 
headline: 
modified: 2016-08-04 09:14:30 -0300
category: programming
tags: [ruby, rails, html]
imagefeature: 
mathjax: 
chart: 
comments: true
featured: false
---

With more than 20 helper modules included by default, Rails surely doesn’t lack options when it comes to generating HTML programmatically. That doesn’t mean you should be using them all, though.

I admit that the post title is a bit of a clickbait, but I mean that question literally. I started my career as a web developer right into Rails, so for a long time the Rails-way was unquestionable for me. "*Writing SQL by hand? No sir, thank you very much but I have `ActiveRecord`, I won't be needing SQL ever again. Good day, sir! I said good day!*", would say my young self. In the same way, I adopted the view helpers almost as dogmas, and would bend my code in ways that resembled some circus artists to make it fit into the default helpers. Of course, once everything got too much out of control, I'd create a helper of my own and sweep everything under the rug. What could go wrong?

With time, I matured from that innocent, inexperienced programmer. I noticed how much time I'd take wandering through the documentation until I was able to fit my edge case into a helper. Several methods implementing the same tag, each one behaving differently depending on how you would call them or with what arguments made everything much harder. Worst, after some time I noticed that I was lacking knowledge about HTML due to relying too much on Rails, and would *also* need to check HTML tag specifications and see how the output should look like. **That won't do**.

I'm not here to bash on Rails helpers, not at all; instead, I'd like to make you ponder about *mindfulness*. A mindful programmer\* is one that make conscious decisions. It's ok to follow standards and patterns without questioning them when you're still starting and struggling with every new piece of information, but as you grow, things won't be as black and white. Question everything and everyone, play the devil's advocate, even if just to agree stronger than ever afterwards.

> Question everything and everyone, play the devil's advocate, even if just to agree stronger than ever afterwards.

Now I want you to take a deep breath. Ready? Consider the example below:

```ruby
COUNTRY_CODES = [
  ['(+1) United States of America', '+1'],
  ['(+55) Brazil', '+55'],
  ...
]
```

```erb
<%= label_tag :filter_by_country_code, 'Country code:' %>
<%= select_tag :area_code, options_for_select(COUNTRY_CODES, @country_code), id: "filter_by_country_code", include_blank: true %>
```

It's a simple select tag that we can use for filtering. It contains one dynamic input (the currently selected filter) and it generates the options based on a constant array. Now, compare it to the following snippet:

```erb
<label for="filter_by_country_code">Country code:</label>
<select id="filter_by_country_code">
  <option></option>
  <% COUNTRY_CODES.each do |text, value| %>
    <option
      value="<%= value %>"
      <%= "selected" if value == @country_code %>
    >
      <%= text %>
    </option>
  <% end %>
</select>
```

How is the first option *objectively* better? Sure, the second one is longer and it may seem alien to someone used to the Rails helpers, but try to make this comparison from a unbiased perspective. What version is more *readable*? I'd say the second, without a doubt: it's completely straightforward and it uses only basic Ruby concepts. Of course, the reader must understand ERB syntax, but aside from that it's plain HTML with some dynamic parts. The first version on the other hand requires the reader to know three dependencies and how to use them: `label_tag`, `select_tag` and `options_for_select`. It may look simple after getting used to it, but *don't underestimate the dangers of cognitive overload*.

It gets worse: last time I checked, there were 4 methods for generating select tags, and 5 for option tags. The ones related to select tags sometimes behave differently depending on whether you're calling them from a form or not (`<%= form.select args %>` opposed to `<%= select args %>`). They also have different outputs depending on how many arguments you pass. You'll most probably do trial and error until you can find the right combination of methods that generates the expected output. *And that's after years working with Rails*. In comparison, the helperless version (or should I say helpless? BA DUM TSSS) is so simple that anyone with minimal programming skills would be able to write it or read it.

Even if you know by heart all the helpers, how is `<%= label_tag :filter_by_country_code, 'Country code:' %>` better than `<label id="filter_by_country_code">Country code:</label>`? The helperless version is even smaller! In the same way, I find `link_to` equivalent to plain anchor tags. Those options are *comparable* in complexity and flexibility, but one requires prior knowledge specific to Rails applications, and the other doesn't. Which one do you think it's simpler for front-end programmers or even designers to understand? Remember, you are not a Rails developer, you are a **developer**. You should always work on transferable skills that will strengthen your power to build better things in the future. It's ok to prefer the helpers, but it's *not* ok to not know the basics of the technology you're using.

> Remember, you are not a Rails developer, you are a **developer**. You should always work on transferable skills that will strengthen your power to build better things in the future.

Now, I should say that there are cases when using helpers do dry up our code and make it more reusable, specially when heavily using conventions, as is the case with the `form_for` method:

```erb
<%= form_for @user do |f| %>
  <%= f.label :email %>
  <%= f.email_field :email %>

  <%= f.label :password %>
  <%= f.password_field :password %>

  <%= f.button %>
<% end %>
```

The alternative for that is not... as quite appealing.

```erb
<form
  action="<%= @user.new_record? users_path : user_path(@user) %>"
  method="<%= @user.new_record? ? 'POST' : 'PATCH' %>"
>
  <!-- Necessary due to IE bug, check http://stackoverflow.com/a/3348524/2908285 -->
  <input name="utf8" type="hidden" value="✓">

  <!-- Necessary due to CSRF protection, check http://stackoverflow.com/a/1571900/2908285 -->
  <input type="hidden" name="authenticity_token" value="<%= form_authenticity_token %>">

  <label for="user_email">Email</label>
  <input id="user_email" type="email" name="user[email]" value="@user.email">

  <label for="user_password">Password</label>
  <input id="user_password" type="password" name="user[password]">

  <button name="button" type="submit"><%= @user.new_record? 'Create' : 'Update' %> User</button>
</form>
```

The automatically added hidden tags are great, and having all of those names and labels set up for us comes in very handy. Even in this case, though, it’s absolutely essential to understand what is the expected output.

You may be thinking that there are several good reasons for always using helpers, even when the alternative is equivalent: internationalization, extensibility by overriding default methods, easiness to refactor, even consistency. All of those motives are perfectly good and valid, and that's exactly the point. Everything that you type should be a mindful decision, not something that you take for granted, nor "the way" of doing things.

There is nothing sacred about programming, only recommended sets of decisions that exist due to previous experiences by other programmers. Understand well the technologies you're using, try to reason about why someone chose certain API design over another, and decide based on facts or personal experience whether that solution is appropriate for your case or not. That is the path of a mindful programmer.

\* *This post is related to an awesome chapter in [The Pragmatic Programmer's book](https://pragprog.com/book/tpp/the-pragmatic-programmer), [Programming by Coincidence](https://pragprog.com/the-pragmatic-programmer/extracts/coincidence). Check it out!*
