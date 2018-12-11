---
layout: post
title: "Code reuse with transducers in ReasonML"
description: "ReasonML's lack of polymorphic behavior makes it hard to reuse data processing pipelines in different contexts. In this post I demonstrate how to use transducers to overcome that limitation."
headline: 
modified: 2018-12-12 02:00:12 +0900
category: personal
tags: [ReasonML, Functional Programming]
imagefeature: 
mathjax: 
chart: 
comments: true
featured: true
---

Transducers may seem hard at first, but in practice you can pretty much ignore
the implementation details and reap their benefits. In this post we'll refactor
some code and make it reusable, overcoming some limitations in the ReasonML
language.

The first time I tried to understand transducers, I thought it was just a
technique to optimize memory consumption by avoiding unnecessary intermediate
steps. Due to my background in object-oriented design, I failed to consider
what makes transducers really shine: complete decoupling between data
transformation, data combination and data source. In a language with
polymorphic behavior like dynamic dispatch in JavaScript or overloading in
Haskell's type classes, that's not so important since you can simply
parameterize the correct implementation. However, in a language such as
ReasonML, transducers provide a powerful tool for code reuse and decoupling.

This post is part of an on-going study of transducers in ReasonML, and for this
entry I won't explain in details how transducers work. For more on that I
recommend watching [Rich Hickey's talk](https://www.youtube.com/watch?v=6mTbuzafcII)
on the subject and reading
[Kyle Simpson's Functional-Light JavaScript](https://github.com/getify/Functional-Light-JS/blob/master/manuscript/apA.md/).
It's enough to say that by parameterizing utilities such as `map` and `filter`
with a function representing the next step in the computation, it's suddenly
possible to build pipelines simply with function composition.

Instead, we'll focus on how transducers can help building maintainable code. To
illustrate, we'll start with a simple example, hard-coded using `List`s, then
migrate to a transducer implementation, then exemplify how function composition
makes refactoring easy, then finally demonstrate how effortless it is to reuse
the same pipeline for other data structures.

```reasonml
type person = { age: int, name: string };

let countAdultsWithInitial = (initial, people) =>
  people
  |> List.filter(person => String.get(person.name, 0) == initial)
  |> List.filter(person => person.age >= 18)
  |> List.length

let people = [
  { age: 16, name: "Alice" },
  { age: 25, name: "Andrew" },
  { age: 34, name: "Ann" },
  { age: 22, name: "Bob" },
];

people
|> countAdultsWithInitial('A')
|> Js.log
```

The code above has two problems: every step in the process creates a new list,
increasing memory consumption. It is also very difficult to adapt into
something other than lists. For example, what if the data is displayed in a
real-time dashboard, coming through a web socket using observables? Or maybe
it's stored in a trie for quick data retrieval in an autocomplete?

Let's refactor the code above into a transducer and see how flexible it becomes:

```reasonml
module T = Transducer;

/* We introduce an infix operator to make it easier to compose long sequences
of function calls */
let (<<) = (f, g) => x => f(g(x));

let countAdultsWithInitial = initial =>
  (+) |> (
    T.filter(person => String.get(person.name, 0) == initial)
    << T.filter(person => person.age >= 18)
    << T.map(_ => 1)
  );

people
|> List.fold_left(countAdultsWithInitial('A'), 0)
|> Js.log
```

Notice that inside the `countAdultsWithInitial` function there's no mention to
lists. It also means that we don't have access to `List.length` anymore, which
forces us to change how we calculate it. In the example above, since we're not
interested in collecting any individual information, after filtering we can
simply map each element into the integer 1, disregarding the record entirely,
and use a sum function. As you may have noticed, what `countAdultsWithInitial`
returns is a reducer, so the only requirement for using it is having a fold
function that works for the data structure of choice.

Let's now take another moment to refactor the code above, showcasing how easy it is to
extract pipelines when your building block is function composition:

```reasonml
/* Ideally, we should be able to use point-free style with the function
composition operator, ommiting the `combine` function, but at the moment I'm
still struggling with ReasonML's type inference, and this was the only way I
could find to make it compile. I'll update the post accordingly as I find
better implementations. */
let adultsWithInitial = (initial, combine) =>
  combine |> (
    T.filter(person => String.get(person.name, 0) == initial)
    << T.filter(person => person.age >= 18)
  );

Js.log("Counting the selected records:");
let countAdultsWithInitial = initial =>
  (+) |> (
    adultsWithInitial(initial)
    << T.map(_ => 1)
  )

people
|> List.fold_left(countAdultsWithInitial('A'), 0)
|> Js.log

Js.log("Collecting the names of the selected records into a string:");
let join = separator => (result, element) => result ++ element ++ separator;
let enumerateAdultsWithInitial = initial =>
  join(", ") |> (
    adultsWithInitial(initial)
    << T.map(person => person.name)
  );

people
|> List.fold_left(enumerateAdultsWithInitial('A'), "")
|> Js.log

Js.log("Collecting the selected records into a list:");
let append = (list, element) => list @ [element];
people
|> List.fold_left(adultsWithInitial('A', append), [])
|> Js.log
```

Now, let's try applying the same transducers, without modification, to a
completely different context. For simplicity, let's use a custom tree data
structure.

```reasonml
module Tree {
  type tree = Empty | Node(person, tree, tree);

  /* Reducing a tree in pre-order traversal */
  let rec reduce = (reducer, result, tree) => {
    switch tree {
      | Empty => result
      | Node(person, left, right) => {
        let resultSelf = reducer(result, person);
        let resultLeft = reduce(reducer, resultSelf, left);
        reduce(reducer, resultLeft, right);
      }
    };
  };
}

let people = Tree.(
  Node(
    { age: 34, name: "Ann" },
    Node(
      { age: 25, name: "Andrew" },
      Node(
        { age: 16, name: "Alice" },
        Empty,
        Empty,
      ),
      Empty,
    ),
    Node(
      { age: 22, name: "Bob" },
      Empty,
      Empty,
    )
  )
);

Js.log("Counting the selected records:");
people
|> Tree.reduce(countAdultsWithInitial('A'), 0)
|> Js.log

Js.log("Collecting the names of the selected records into a string:");
people
|> Tree.reduce(enumerateAdultsWithInitial('A'), "")
|> Js.log

Js.log("Collecting the selected records into a list:");
people
|> Tree.reduce(adultsWithInitial('A', append), [])
|> Js.log
```

As you can see, as long as there's a reduce (or fold) function, you can use the
same pipelines without modification.

Transducers allow for code that represents the data processing itself,
decoupled from data structures and with a simple-to-adhere interface. The
mental leap to use them is very small, but their benefits are great. Try using
them and see for yourself!

_As I mentioned in the beginning, this is only the first part of an on-going
series. Next time I plan to introduce early-termination transducers (such as
`take`), while properly cleaning up resources to avoid memory leaks (I expect
to use Rx's observables for that). I'll also update this post from time to time
while I learn better ways to use transducers in ReasonML._

_If you wish to manually test the pieces of code above, or if you'd like to
experiment with transducers yourself, here's a repository containing all I have
so far: [https://github.com/oddlyfunctional/bs-transducers/tree/first-post](https://github.com/oddlyfunctional/bs-transducers/tree/first-post)._
