---
layout: post
title: "Making a game with Functional Programming - Part 1"
description: "Let's make a point-and-click adventure game using Functional Programming! In this first post, we'll write a simple code to render moving squares while introducing some basic concepts of game development."
headline: 
modified: 2016-09-19 14:58:05 -0300
category: personal
tags: [JavaScript, Functional Programming, Game Development]
imagefeature: 'covers/day-of-the-tentacle.jpg'
mathjax: 
chart: 
comments: true
featured: false
---

Games are essentially stateful mediums: there are levels, items, character statuses, camera position, etc. The world state changes on every game loop, dozens of times per second, not only reacting to events but constantly. They are also very easy to think in terms of Object Oriented Design: characters have attributes like speed and actions like "move". Therefore, I always thought it'd be hard to use functional programming for game development. In fact, it may be simply impractical for performance-heavy games that need to trim each millisecond possible. However, there is no reason not to *try* it for a simple game.

This is precisely why I'm beginning this series: to see how feasible it is, or what difficulties I'll find while developing a small game with FP. For this, I'll be writing a point-and-click adventure game, based on classic LucasArts' masterpieces like Day of the Tentacle and Monkey Island. I chose this genre because it is simple enough to avoid many of the common complexities of developing a game, while giving plenty of space to experiment with state changes (inventory, dialogue options, triggers, etc.) and a bit of path-finding algorithms.

Our goal today is simple: to write some code that will render a moving drawing. Nothing too ambitious, just enough to get us started. Before we move forward, though, it's important to make some points clear:

* I'll be using some ES2015 features, like [`Object.assign`](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Object/assign);
* This is an experiment, so the code you'll see here is far from what a real application would need;
* I'm starting from the basics, so if you're a more advanced game developer this is probably not for you.

For starters, a bit of concepts on game development. A video game as we understand it today is an interactive program that continuously calculates an updated world state and renders a new representation of that state (a frame), while being able to receive inputs from the user and process them to change the state. This means that, differently from a server responding to an HTTP request or a widget responding to user interaction, we need a program that doesn't finish. Everything in the game happens inside of what is called a game loop, so let's start with that. One thing you'll notice is that this layer of our program is, by definition, impure. We need a place to produce side-effects, otherwise the user wouldn't ever notice things changed, so the pure part of our game will be the `update`, and the loop and rendering parts are impure (I realize I could use the IO monad to pack renderings as pure functions, but at the moment I'm unsure of how I'd do that).

{% highlight javascript linenos=table %}
let state = {};

while (true) {
  state = update(state);
  render(state);
}

function update(state) {
  let x = state.x || 0;
  return Object.assign(state, { x: x + 1 });
}

function render(state) {
  console.log(state);
}
{% endhighlight %}

If you paste this code in your browser, you'll probably regret it. That's because JavaScript runs in a single thread and is IO-blocking, and since this code never finishes, it'll freeze the interface (if you use Chrome, you'll be able to kill only the tab that's running the loop). We need a better way. We need to execute a function repeatedly but freeing the interface after each iteration. Maybe we could use the `setInterval` function:

{% highlight javascript linenos=table %}
function gameLoop() {
  state = update(state);
  render(state);
}

setInterval(gameLoop, 0);
{% endhighlight %}

That works great! There is, however, a nice feature that most of the browsers implement nowadays called [`requestAnimationFrame`](https://developer.mozilla.org/en-US/docs/Web/API/window/requestAnimationFrame). You can read more about it and how to polyfill it for browsers that lack support on this [excellent post](http://www.paulirish.com/2011/requestanimationframe-for-smart-animating/) from [Paul Irish](https://twitter.com/paul_irish), but basically it is more optimized while saving battery at the same time. Let's use that!

{% highlight javascript linenos=table %}
function gameLoop() {
  state = update(state);
  render(state);
  window.requestAnimationFrame(gameLoop);
}

window.requestAnimationFrame(gameLoop);
{% endhighlight %}

Awesome, we have a working game loop and some state being updated! Now we need to render that state into the screen, and for that we'll use the [canvas element](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial). This is the HTML that's going to render our game:

{% highlight html linenos=table %}
<!DOCTYPE html>
<html>
  <head>
    <title>Making a game with Functional Programming</title>
  </head>

  <body>
    <canvas id="game" width="480" height="320">
      We can add some fallback code here!
    </canvas>
    <script src="game.js"></script>
  </body>
</html>
{% endhighlight %}

And then we can get hold of the canvas in the JavaScript:

{% highlight javascript linenos=table %}
let canvas = document.getElementById('game');
let ctx = canvas.getContext('2d');
{% endhighlight %}

In this series we'll use the 2d context, but we could use the same canvas for [drawing 3d games](https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/getContext). The context exposes some methods for drawing lines, rectangles, text, PNG files, etc, so let's use it in our render method:

{% highlight javascript linenos=table %}
let canvas = document.getElementById('game');
let ctx = canvas.getContext('2d');
let state = {};
window.requestAnimationFrame(gameLoop);

function gameLoop() {
  state = update(state);
  render(state, ctx, canvas);
  window.requestAnimationFrame(gameLoop);
}

function update(state) {
  let x = state.x || 0;
  return Object.assign(state, { x: x + 1 });
}

function render(state, ctx, canvas) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = 'rgb(0, 0, 200)';
  ctx.fillRect(state.x, 0, 20, 20);
}
{% endhighlight %}

You should see a small blue square running through the screen:

<iframe src="https://embed.plnkr.co/VCw5xuKoMz9mhuyO2aHa/" frameborder="0" width="100%" height="500"></iframe>

The [`ctx.clearRect`](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/clearRect) method clears the screen for the next frame, otherwise we'd keep drawing on top of the previous frame (try commenting out that line in the Plunker and see what happens). The [`ctx.fillStyle`](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fillStyle) defines the style for the next drawings, and the [`ctx.fillRect`](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fillRect) draws the square at the position defined on `state.x`.

Just to illustrate how we can use the game state to dynamically generate new objects, let's update our code to randomly add new squares to the canvas. In order to schedule square creations, we also need a way to know the current time, so we'll pass it as an argument to the `update` function:

{% highlight javascript linenos=table %}
function gameLoop() {
  state = update(state, Date.now());
  render(state, ctx, canvas);
  window.requestAnimationFrame(gameLoop);
}

function update(state, now) {
  let { squares, nextSquareAt } = state;
  nextSquareAt = nextSquareAt || 0;
  squares = squares || [];

  if (now >= nextSquareAt) {
    // Math.random() is not quite a pure function, but let's ignore that for now
    let newSquare = { x: 0, y: Math.random() * 200, size: Math.random() * 50  };

    squares = squares.concat([newSquare]);

    // Schedules the next square for a random value between 0 and 1000 milliseconds
    nextSquareAt = now + Math.random() * 1000;
  }

  squares = squares.map(square => {
    return { x: square.x + 1, y: square.y, size: square.size  }
  });

  return Object.assign(state, { squares, nextSquareAt });
}

function render(state, ctx, canvas) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = 'rgb(0, 0, 200)';

  state.squares.forEach(square => {
    ctx.fillRect(square.x, square.y, square.size, square.size);
  });
}
{% endhighlight %}

Before we finish, the code above has a serious problem: it infinitely creates squares but never gets rid of the ones that have escaped from the screen. This means that the memory consumption will grow as the time passes, which characterizes a memory leak. Let's change the `update` function to consider that:

{% highlight javascript linenos=table %}
const CANVAS_WIDTH = canvas.width;

function update(state, now) {
  let { squares, nextSquareAt } = state;
  nextSquareAt = nextSquareAt || 0;
  squares = squares || [];

  if (now >= nextSquareAt) {
    // Math.random() is not quite a pure function, but let's ignore that for now
    let newSquare = { x: 0, y: Math.random() * 200, size: Math.random() * 50  };

    squares = squares.concat([newSquare]);

    // Schedules the next square for a random value between 0 and 1000 milliseconds
    nextSquareAt = now + Math.random() * 1000;
  }

  squares = squares.map(square => {
    return { x: square.x + 1, y: square.y, size: square.size }
  }).filter(square => square.x <= CANVAS_WIDTH);

  // Just to make sure that we're really removing the squares
  console.log(squares.length);

  return Object.assign(state, { squares, nextSquareAt });
}
{% endhighlight %}

And here's our finished version:

<iframe src="https://embed.plnkr.co/u1HnwXccnnYJFSxyA98c/" frameborder="0" width="100%" height="500"></iframe>

So far this example may seem too simplistic, but it actually establishes the foundation for almost any game you can think of. We wrote a small game loop comprised of an update phase and a render phase (depending on the game, you may need to separate them in two threads), added some randomness and treated memory leaks. You'll use those concepts again and again while developing games. The next posts will cover in more detail topics like reacting to user's interactions, rendering images with transparency, animating sprites, playing sounds, and several other aspects that will make our game look like a game.

Did you like this post? Have any complaints about my poor functional skills? Leave a comment below and let me know!
