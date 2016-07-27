---
layout: post
title: "Finding words in a UNIX-like system (or how to create a unique username)"
description: "How to come up with a unique username using UNIX tools to help you find out words."
headline: "How to come up with a unique username using UNIX tools to help you find out words."
modified: 2016-07-27 15:18:15 -0300
category: personal
tags: [unix, bash, marketing]
imagefeature: 
mathjax: 
chart: 
comments: true
featured: true
---

Even though it's an essential part of marketing yourself, I could never come up
with a proper username that would work across different services. Today I
decided that I would find one, no matter what. It should be easy to write, easy
to remember, easy to understand in a spoken conversation and, in a less
measurable dimension, it should *sound* good.

The first step was finding a sistematic way to check whether a username was
available in different services. There are several websites that do exactly
that, I've used [checkusernames.com](http://checkusernames.com/), which is
easier to scan quickly since everthing fits in less than two pages (you can get
it to fit in one page with some simple CSS manipulation in the dev tools), and
[Namech_k](https://namechk.com/), which checks some different services, like
Facebook, and also domains.

After experimenting with variations of my name and then some crazy things for a
few hours (*horselovingmartian* was a serious option at one point), I
determined that it would be a joke with the word "functional". Problem is,
"functional" is a 10 letter word, and Twitter has an annoying limit of 15
characters for usernames, leaving me with only 5 characters to work with. Some
of the best ones didn't fit, and some others were taken. I almost flipped the
table when I came up with *barelyfunctional* only to find out it had 1 extra
character.

Damn.

I yielded: I'm not that good at inventing names (specially in a language that's
not my native one), so to overcome this obstacle I would need to use my other
skills. I would find a list of words, programatically apply some
constraints, and choose from the options in the resulting list.

Some time ago I released a small game for a [Ludum
Dare](http://ludumdare.com/) called [I AM GONNA SMACK YOU WITH MY
WORDS!](http://gamedev-mrodrigues.rhcloud.com/portfolio/i-am-gonna-smack-you-with-my-words/)
(pretty fun, you should check it out!) for which I needed a dictionary to
validate the user entries. After some digging, I've found out: every default
UNIX-like installation has a
[list of words](https://en.wikipedia.org/wiki/Words_(Unix)), usually at
`/usr/share/dict/words` or `/usr/dict/words`:

```bash
$ cat /usr/share/dict/words | less
```

That's awesome, let's use that! But how many words does it contain?

```bash
$ cat /usr/share/dict/words | wc -l
99171
```

Wow, ok, that's a lot. Let's do some filtering, including only the words that contain between 1 and 5 characters:

```bash
$ cat /usr/share/dict/words | grep "^\w\{1,5\}$" | wc -l
10311
```

Still not very helpful. I figured that a lot of words were proper nouns, so we could remove the ones starting with a capital letter:

```bash
$ cat /usr/share/dict/words | grep "^[a-z]\w\{1,4\}$" | wc -l<Paste>
7583
```

Hmm, still a lot of work. I really like adjectives that end with *ly*, like *barely*, so I gave it a shot:

```bash
$ cat /usr/share/dict/words | grep "^[a-z]\w\{1,2\}ly$" | wc -l
72
```

Aha! That's more manageable. Now you can read it with `less` or save it to a file and read it in your favourite editor:

```bash
$ cat /usr/share/dict/words | grep "^[a-z]\w\{1,2\}ly$" > awesome_adjectives.txt
```

This is a common pattern for handling huge inputs, you start massaging it,
figuring out patterns and excluding them, until you have a dataset which's size
is workable.

Just for curiosity, here's a Ruby script to accomplish the same:

```ruby
# I'm using each_line so we don't load everyhing into memory at the same time
awesome_adjectives = File.open('/usr/share/dict/words', 'r')
                       .each_line
                       .select { |line| line =~ /^[a-z].*ly$/ }
```

That's it! Keep experimenting!
