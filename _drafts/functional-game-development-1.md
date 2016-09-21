# Making a game with Functional Programming - Part 1

Games are essentially stateful mediums: there are levels, items, character statuses, camera position, etc. The world state changes on every game loop, dozens of times per second, not only reacting to events. They are also very easy to think in terms of Object Oriented Design: characters have attributes like speed and actions like "move". Therefore, I always thought it'd be hard to use functional programming for game development. In fact, it may be simply impractical for performance-heavy games that need to trim each millisecond possible (I wouldn't say for sure, though, as I have not tried). However, there is no reason not to *try* it for a simple game.

This is precisely why I'm beginning this series: to see how feasible it is, or what difficulties I'll find while developing a small game with FP. For this, I'll be writing a point-and-click adventure game, based on classic LucasArts' masterpieces like Day of the Tentacle and Monkey Island. I chose this genre because it is simple enough to avoid many of the common complexities of developing a game, while giving plenty of space to experiment with state changes (inventory, dialogue options, triggers, etc.) and a bit of path-finding algorithms. I also chose it because I love it, so deal with it.

Disclaimer: I'll try to keep it to a minimum, but I'm using some ES2015 features here, like `Object.assign`.

For starters, a bit of concepts on game development. A video game, in the sense that we understand today, is an interactive program that continuously calculates an updated world state and renders a new representation of that state (a frame), while being able to receive inputs from the user and process them to change the state. This means that, differently from a server responding to an HTTP request or a widget responding to user interaction, we need a program that doesn't end. This is called a game loop, and let's start with that. One thing you'll notice is that this layer of our program is, by definition, non-pure. We need a place to produce side-effects, otherwise the user wouldn't ever notice things changed, so the pure part of our game will be the `update`, and the loop and rendering are impure (I realize I could use the IO monad to pack renderings as pure functions, but at the moment I'm unsure of how I'd do that).

```javascript
var state = {};

while (true) {
  state = update(state);
  render(state);
}

function update(state) {
  var x = state.x || 0;
  return Object.assign(state, { x: x + 1 });
}

function render(state) {
  console.log(state);
}
```

If you paste this code in your browser, you'll probably regret it. That's because JavaScript runs in a single thread and is IO-blocking, and since this code never finishes, it'll freeze the interface (if you use Chrome, you'll be able to kill the tab that's running the loop). We need a better way. We need some to execute a function repeatedly but freeing the interface after each iteration. Maybe we could use the `setInterval` function:

```javascript
function gameLoop() {
  state = update(state);
  render(state);
}

setInterval(gameLoop, 0);
```

That works great! There is, however, a nice feature that most of the browsers implement nowadays called `requestAnimationFrame`. You can read more about it and how to polyfill it for browsers that lack support on this [excellent post](http://www.paulirish.com/2011/requestanimationframe-for-smart-animating/) from [Paul Irish](https://twitter.com/paul_irish). Let's use that!

```javascript
function gameLoop() {
  state = update(state);
  render(state);
  window.requestAnimationFrame(gameLoop);
}

window.requestAnimationFrame(gameLoop);
```

Awesome, we have a working game loop and some state being updated! Now we need to render that state into the screen, and for that we'll use the [canvas element](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial). This is the HTML that's going to render our game:

```html
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
```

And then we can get hold of the canvas in the JavaScript:

```javascript
var canvas = document.getElementById('game');
var ctx = canvas.getContext('2d');
```

In this series we'll use the 2d context, but we could use the same canvas for [drawing 3d games](https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/getContext). The context exposes some methods for drawing lines, rectangles, text, PNG files, etc, so let's use it in our render method:

```javascript
var canvas = document.getElementById('game');
var ctx = canvas.getContext('2d');
var state = {};
window.requestAnimationFrame(gameLoop);

function gameLoop() {
  state = update(state);
  render(state, ctx, canvas);
  window.requestAnimationFrame(gameLoop);
}

function update(state) {
  var x = state.x || 0;
  return Object.assign(state, { x: x + 1 });
}

function render(state, ctx, canvas) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = 'rgb(0, 0, 200)';
  ctx.fillRect(state.x, 0, 20, 20);
}
```

You should see a small blue square running through the screen:

<iframe src="https://embed.plnkr.co/VCw5xuKoMz9mhuyO2aHa/" frameborder="0" width="100%" height="500"></iframe>
