---
layout: post
title: "Functional Programming - Pure Functions"
description: 
headline: 
modified: 2016-09-06 18:51:12 -0300
category: personal
tags: [JavaScript, Functional Programming]
imagefeature: 
mathjax: 
chart: 
comments: true
featured: false
---
Functional programming made a huge comeback in the recent years, after decades of being little more than an academic curiosity for most of the industry (Haskell's unofficial slogan is "avoid success at all costs"). Its fame is well deserved, but its barrier of entry sometimes may seem too high. Amidst monads, functors, transducers and a *lot* of other arcane terms, newcomers simply don't know where to begin. They may even feel stupid, thinking it's just too hard for them. I know I have.

Living up to the username I chose, I decided to start this series, filled with practical examples to demonstrate how we can apply functional programming concepts to our everyday code. Now, instead of trying to define what it is (you have [Wikipedia](https://en.wikipedia.org/wiki/Functional_programming) for that), I'll start showing the most fundamental, trivial and impacting idea that is both the cornerstone in which all of the other concepts are built upon and the reason for them to exist in the first place: pure functions.

Function purity is a simple idea that has a tremendous impact in your application: they are functions in the mathematical sense, meaning that they:

1) Don't produce side-effects (changing value of variables, writing to the database, changing the DOM, modifying properties of the parameters it receives, etc);
2) Work only on the inputs they explicitly receive (meaning that they don't use any variables or classes that aren't included in the incoming parameters, including the pointer to the current instance, `this` or `self`);

You could imagine a pure function as an opaque box that receives a number of things on one side, emits some weird noises and then expels something on the other side. Its internals are unimportant for whatever client using it, since the only thing that matters is the output. It's easy to infer that, given the same inputs, a pure function is guaranteed to return the same output, since it doesn't depend on anything else. Also, because of the rule 1), if a pure function doesn't return anything, its only purpose is to burn CPU cycles with no visible effect.

Let's see an example:

```javascript
// First let's define an assert function that will help us test our code:
function assert(result, message) {
  if (!result) { throw new Error(message); }
}

var cart = {
  total: 0,
  items: [
    { price: 10 },
    { price: 5 },
    { price: 20 },
    { price: 18 }
  ]
};

function calculateTotal() {
  cart.items.forEach(function (item) {
    cart.total += item.price;
  });
}

calculateTotal();
assert(cart.total === 53, "Total is different than 53");
```

The function above violates both of the constraints defined previously: it depends on a `cart` variable being defined in the enclosing scope and it causes side-effects by changing external state. Not only that, it also requires that the cart object contains a total property initialized with the value zero, a situation that I call *context state dependency*, meaning that the function is defined in a way it can only be under a certain, non-explicit context.

All of this makes this code difficult to maintain. What if the requirements change and we need to include multiple data sources to fill the cart’s items? The function `calculateTotal` is not [idempotent](https://en.wikipedia.org/wiki/Idempotence#Computer_science_meaning), therefore it needs to be called only once after all the data is present.

Let's do some refactoring:

```javascript
// This implementation removes the context state
// dependency by initializing the state as needed.
function calculateTotal() {
  var total = 0;
  cart.items.forEach(function (item) {
    total += item.price
  });
  cart.total = total;
}

// This implementation removes the dependency on
// non-explicit parameters by receiving the
// cart as an argument.
function calculateTotal(cart) {
  var total = 0;
  cart.items.forEach(function (item) {
    total += item.price
  });
  cart.total = total;
}

// This implementation removes the side-effects by
// returning the total instead of changing the cart's property.
// In this case, the responsibility of altering the state
// belongs to whoever is calling this function.
function calculateTotal(cart) {
  var total = 0;
  cart.items.forEach(function (item) {
    total += item.price
  });
  return total;
}

// This implementation reduces the coupling with the
// cart's structure by simply receiving a list of
// items containing prices.
function calculateTotal(items) {
  var total = 0;
  items.forEach(function (item) {
    total += item.price
  });
  return total;
}


// Finally, we can test it is working fine without even needing a cart.
assert(calculateTotal([
  { price: 10 },
  { price: 5 },
  { price: 20 },
  { price: 18 }
]) === 53, "Total is different than 53");
```

As you can see, it's much easier to test this implementation, since it doesn't depend on any non-explicit context. It is also much more composable as well, since it produces a value instead of altering state. Here an example of how we could reuse it to calculate a store's total income:

```javascript
var orders = [
  {
    items: [{ price: 10 }, { price: 5 }]
  },
  {
    items: [{ price: 20 }, { price: 9 }]
  },
  {
    items: [{ price: 7 }]
  }
];

// First we calculate the orders' totals:
var ordersTotals = orders
                     .map((order) => order.items)       // Extracting items
                     .map(calculateTotal)               // Calculating each order's total
                     // I had to write an explicit block below because unfortunately
                     // the JS parsers would think that the brackets around the
                     // object were block delimiters.
                     .map((price) => { return { price: price } }); // Defining the structure required by the calculateTotal function

// Then we calculate the whole income:
assert(calculateTotal(ordersTotals) === 51, "Store's income is different than 10");
```

You could argue that we're still altering state inside of the function, by creating a `total` variable and updating it on each iteration. You would be correct, but since the state we're mutating exists only inside of our function's scope, to the outside world it is perfectly pure. Or, as Rich Hickey, creator of Clojure, puts it:

> "If a tree falls in the woods, does it make a sound? If a pure function mutates data to produce an immutable value, is that ok?" ~ [@richhickey](https://twitter.com/richhickey)

Let's see another example, this time using a common data structure:

```javascript
function ImpureTree(value, children) {
  this.value = value;
  this.children = children;
}

ImpureTree.prototype.setValue = function(value) {
  this.value = value;
}

ImpureTree.prototype.addChild = function(child) {
  this.children.push(child);
}

ImpureTree.prototype.sum = function() {
  var total = 0;
  this.children.forEach((child) => total += child.sum());
  return this.value + total;
}

var tree = new ImpureTree(0, []);
tree.setValue(1);
var child = new ImpureTree(2, []);
tree.addChild(child);

assert(tree.sum() === 3, "Tree's sum is not 3");

child.setValue(3);
assert(tree.sum() === 4, "Tree's sum is not 4");


function PureTree(value, children) {
  this.value = value;
  this.children = children;
}

PureTree.prototype.setValue = function(value) {
  return new PureTree(value, this.children);
}

PureTree.prototype.addChild = function(child) {
  return new PureTree(this.value, this.children.concat([child]));
}

PureTree.prototype.sum = function() {
  var total = 0;
  this.children.forEach((child) => total += child.sum());
  return this.value + total;
}

var tree = new PureTree(0, []);
tree = tree.setValue(1);
var child = new PureTree(2, []);
tree = tree.addChild(child);

assert(tree.sum() === 3, "Tree's sum is not 3");

child.setValue(3);
assert(tree.sum() === 3, "Tree's sum is not 3");
```

The clear advantage of immutable data structures is that we can safely pass them around, even share them in parallel programs, and they'll always correctly represent the values with which they were instantiated. This is not true for the impure version: if we change the child's sum, we're affecting the parent's sum as well. This makes it much harder to debug, since effectively it is non-deterministic: at any given point in time, there is no way to ensure which piece of code changed the state besides inspecting each line that mutates any child, through each step that leads to the desired context. If the references are shared among several parts of the program, this task may be, if not unfeasible, at least highly unpleasant. Throw in some race conditions and we have a delicious recipe for a disaster.

I admit that I'm stretching the definition of a pure function a little bit by using the `this` keyword, since it's an implicit argument, but since the state is never updated it doesn't cause the known mutation problems. We could easily avoid that with a similar, but less efficient implementation:

```javascript
function PureTree(value, children) {
  // This will re-create the same `setValue`, `addChild` and `sum`
  // functions every time a new tree is instantiated.
  // This consumes more memory than defining them once
  // in the prototype, which may be a problem depending
  // on the size of the data set.
  return {
    setValue: setValue,
    addChild: addChild,
    sum: sum
  };

  function setValue(value) {
    return new PureTree(value, children);
  }

  function addChild(child) {
    return new PureTree(value, children.concat([child]));
  }

  function sum() {
    var total = 0;
    children.forEach((child) => total += child.sum());
    return value + total;
  }
}

var tree = new PureTree(0, []);
tree = tree.setValue(1);
var child = new PureTree(2, []);
tree = tree.addChild(child);

assert(tree.sum() === 3, "Tree's sum is not 3");

child.setValue(3);
assert(tree.sum() === 3, "Tree's sum is not 3");
```

This was all very interesting, but what about one of the more common use cases in the front-end development: performing asynchronous requests and updating the DOM accordingly at the end? Here's a simple case:

```javascript
function impureNotifications() {
  $.getJSON(NOTIFICATIONS_URL, { userId: USER_ID }).then(function(notifications) {
    var html = '';
    notifications.forEach(function(notification) {
      html += '<li>' + notification.text + '</li>';
    });
    $('#notifications').html(html);
  });
}

setInterval(impureNotifications, 1000);
```

The code above implements a simple polling system to update the user's notifications widget: every 1000 milliseconds a new request is made, and when the response comes, the widget element is updated with a new HTML. If we were to test this code, the first thing we'd need to do is stub the `$.getJSON` function:

```javascript
function mockPromise(response) {
  return {
    then: then
  };

  function then(callback) {
    callback(response);
  }
}

var notifications = [
  { text: "Mom called" },
  { text: "BFF stopped following you" }
];
$.getJSON = () => mockPromise(notifications);

impureNotifications();

assert(
  $('#notifications').html() === "<li>Mom called</li><li>BFF stopped following you</li>",
  "DOM wasn't updated correctly"
);
```

Now, let's do some purification:

```javascript
// First let's define a `assertEquals` function that
// allows us to compare arrays by equality, 'cause JavaScript.
function assertEquals(got, expected) {
  got = JSON.stringify(got);
  expected = JSON.stringify(expected);
  if (got !== expected) {
    throw new Error("Expected " + expected + ", but got " + got);
  }
}

// Pure part
function pureRenderNotification(notification) {
  return '<li>' + notification.text + '</li>';
}

assertEquals(
  pureRenderNotification({ text: 'Something' }),
  "<li>Something</li>"
);

function pureRenderNotifications(notifications) {
  return notifications.map(pureRenderNotification);
}

assertEquals(
  pureRenderNotifications([
    { text: 'Something' },
    { text: 'Another thing' }
  ]),
  ["<li>Something</li>", "<li>Another thing</li>"]
);

function pureFetchNotifications(notificationsUrl, userId) {
  return function($) {
    return $.getJSON(notificationsUrl, { userId: userId });
  };
}

var notifications = [
  { text: "Mom called" },
  { text: "BFF stopped following you" }
];
var called = false;
pureFetchNotifications('someUrl', 1)({ getJSON: () => mockPromise(notifications) })
  .then(function(receivedNotifications) {
    called = true;
    assertEquals(notifications, receivedNotifications);
  });

assert(called, "Callback wasn't called.");

function pureUpdateNotifications(notifications) {
  return function(html) {
    notifications.html(html);
  };
}

var targetHtml;
var expectedHtml = "<li>Something</li>";
pureUpdateNotifications({ html: (_html) => targetHtml = _html })(expectedHtml);
assertEquals(targetHtml, expectedHtml);

// Impure part
function impureNotifications() {
  pureFetchNotifications(NOTIFICATIONS_URL, USER_ID)($)
    .then(pureRenderNotifications)
    .then(pureUpdateNotifications($('#notifications')));
}

setInterval(impureNotifications, 1000);
```

One thing you may have noticed is that a clear separation emerges in the program: pure and impure functions have distinct goals and must be approached with different mindsets. There is no escape, at some point there is going to be some impurity, otherwise our programs would be closed boxes that never communicate with the outside world. However, we can define the core of our applications as sets of pure, deterministic and easily testable modules that perform all sorts of complex operations, wrapped in a thin, impure layer that's responsible for the side-effects, event handling and state management. In other words, as long as we can keep our non-determinism contained, our programs will be much more maintainable.

You can test that the previous code works by booting up a simple server like [json-server](https://github.com/typicode/json-server) (awesome lib!) and requiring [jQuery](https://jquery.com/):

*notifications.json*:
```json
{
  "notifications": [
    {
      "text": "Mom called",
      "userId": 1
    },
    {
      "text": "BFF stopped following you",
      "userId": 2
    }
  ]
}
```

```bash
npm -g install json-server
json-server --watch notifications.json
```

*notifications.html*:
```html
<!DOCTYPE>
<html>
  <head>
    <script src="https://code.jquery.com/jquery-3.1.0.min.js" integrity="sha256-cCueBR6CsyA4/9szpPfrX3s49M9vUU5BgtiJj06wt/s=" crossorigin="anonymous"></script>
  </head>
  <body>
    <ul id="notifications"></ul>
    <script>
      // Pure part
      function pureRenderNotification(notification) {
        return '<li>' + notification.text + '</li>';
      }

      function pureRenderNotifications(notifications) {
        return notifications.map(pureRenderNotification);
      }

      function pureFetchNotifications(notificationsUrl, userId) {
        return function($) {
          return $.getJSON(notificationsUrl, { userId: userId });
        };
      }

      function pureUpdateNotifications(notifications) {
        return function(html) {
          notifications.html(html);
        };
      }

      // Impure part
      function impureNotifications() {
        pureFetchNotifications(NOTIFICATIONS_URL, USER_ID)($)
          .then(pureRenderNotifications)
          .then(pureUpdateNotifications($('#notifications')));
      }

      var NOTIFICATIONS_URL = "http://localhost:3000/notifications";
      var USER_ID = 1;
      setInterval(impureNotifications, 1000);
    </script>
  </body>
</html>
```

Just open the `notifications.html` file in any browser and there you go. You can play with the values inside of `notifications.json` at will, changing the `userId` property of any entry or adding and removing new entries, and checking the changes being reflected by the polling system in the browser.

I hope you had a good time with this little bit of functional programming (it *has* fun in the name, after all).  These examples may be too simple to reflect how profoundly applying this constraint changes your code, but with some imagination you can extrapolate its long-term effects. Surely you'll think about your code differently from now on: even if you choose not to adopt purity, you'll be more aware of your design choices.

That's it for today, join me next time when I'll talk about higher-order functions (hint: you've been using them all along!), currying and partial application!
