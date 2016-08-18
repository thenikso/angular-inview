# InView Directive for AngularJS

A directive to evaluate an expression if a DOM element is or not in the current
visible browser viewport.

Version 2 of this directive uses a lightwight embedded reactive framework and is
a complete revrite of v1.

## Installation

### With npm

```
npm install agular-inview@beta
```

### With bower

```
bower install angular-inview
```

or [npm](https://www.npmjs.com/):

```
npm install angular-inview
```

## Setup

In your document include this scripts:

```
<script src="/node_modules/angular/angular.js"></script>
<script src="/node_modules/angular-inview/angular-inview.js"></script>
```

In your AngularJS app, you'll need to import the `angular-inview` module:

```
angular.module('myModule', ['angular-inview']);
```

## Usage

This module will define two directives: `in-view` and `in-view-container`.

### InView

```
<any in-view="{expression using $inview}" in-view-options="{object}"></any>
```

The `in-view` attribute must contain a valid [AngularJS expression](http://docs.angularjs.org/guide/expression)
to work. When the DOM element enter or exits the viewport, the expression will
be evaluated. To actually check if the element is in view, the following data is
available in the expression:

- `$inview` is a boolean value indicating if the DOM element is in view.
If using this directive for infinite scrolling, you may want to use this like
`<any in-view="$inview&&myLoadingFunction()"></any>`.
- `$inviewpart` is undefined or a string either `top`, `bottom`, `both` or `neither`
indicating which part of the DOM element is visible.
- `$event` is the DOM event that triggered the check; the DOM element that
changed its visibility status is passed as `$event.inViewTarget`
(To use the old `$element` variable use version 1.3.x).

An additional attribute `in-view-options` can be specified with an object value
containing:

- `offset`: a number (in pixels) indicating how much to move down (or up if negative)
  the top position of the element. As of version 1.5.1, if the number is suffixed
  with `%` then the offset is applied as a percentage instead of pixels.
  position of the element for the purpose of inview testing
- `offsetTop` and `offsetBottom`: two numbers representing the top and bottom
  offset respectively; this may virtually change the height of the element for
  inview testing
- `throttle`: a number indicating a millisecond value of throttle which will
  limit the in-view event firing rate to happen every that many milliseconds

### Examples

The following triggers the `lineInView` when the line comes in view:

```
<li ng-repeat="t in testLines" in-view="lineInView($index, $inview, $inviewpart)">This is test line #{{$index}}</li>
```

**See more examples in the [`examples` folder](./examples).**

### InViewContainer

Use `in-view-container` when you have a scrollable container that contains `in-view`
elements. When an `in-view` element is inside such container, it will properly
trigger callbacks when the container scrolls as well as when the window scrolls.

```
<div style="height: 150px; overflow-y: scroll; position: fixed;" in-view-container>
	<div style="height:300px" in-view="{expression using $inview}"></li>
</div>
```
