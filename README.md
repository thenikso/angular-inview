# InView Directive for AngularJS

A directive to evaluate an expression if a DOM element is or not in the current
visible browser viewport.

The directive is inspired by the [jQuery.inview](https://github.com/zuk/jquery.inview)
plugin. However this implementation has no dependency on jQuery.

## Installation

To install using [Bower](http://bower.io):

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
<script src="/bower_components/angular/angular.js"></script>
<script src="/bower_components/angular-inview/angular-inview.js"></script>
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

An additional attribute `in-view-options` can be speficied with an object value
containing:

- `offset`: a number indicating how much to move down (or up if negative) the top
position of the element for the purpose of inview testing;
- `offsetTop` and `offsetBottom`: two numbers representing the top and bottom
offset respectively; this may virtually change the height of the element for inview testing;
- `debounce`: a number indicating a millisecond value of debounce which will delay
firing the in-view event until that number of millisecond is passed without a scrolling
event happening.

### InViewContainer

Use `in-view-container` when you have a scollable container that contains `in-view`
elements. When an `in-view` element is inside such container, it will properly
trigger callbacks when the container scrolls as well as when the window scrolls.

```
<div style="height: 150px; overflow-y: scroll; position: fixed;" in-view-container>
	<div style="height:300px" in-view="{expression using $inview}"></li>
</div>
```

## How to contribute

1. Fork the repository and clone it to your machine
2. Modify `angular-inview.coffee` and compile it with `coffee -cw angular-inview.coffee` (make sure that *coffeescript* is installed globally)
3. Run `bower install`, `npm install` (make sure that *nodejs*, *npm* and *bower* are installed globally)
4. Run tests by issuing: `karma start` (make sure, that *karma-cli* is installed globally)
5. Commit your changes and create a PR

## License

MIT
