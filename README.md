# InView Directive for AngularJS

A directive to evaluate an expression if a DOM element is or not in the current
visible browser viewport.

The directive is inspired by the [jQuery.inview](https://github.com/zuk/jquery.inview)
plugin. However this implementation has no dependency on jQuery.

## Intallation

To install using [Bower](http://bower.io):

```
bower install angular-inview
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
<any in-view="{expression using $inview}" in-view-offset="{number}"></any>
```

The `in-view` attribute must contain a valid [AngularJS expression](http://docs.angularjs.org/guide/expression)
to work. When the DOM element enter or exits the viewport, the expression will
be evaluated. To actually check if the element is in view, the following data is
available in the expression:

- `$inview` is a boolean value indicating if the DOM element is in view
- `$inviewpart` is undefined or a string either `top`, `bottom` or `both`
indicating which part of the DOM element is visible.
- `$element` is the DOM element that changed its visibility status.

An additional attribute `in-view-offset` can be speficied to add a virtual
offset to the element that will anticipate or delay the in view event.
The offset can be:

- a number: indicating how much to move down (or up if negative) the top
position of the element for the purpose of inview testing;
- an array of two numbers representing the top and bottom offset respectively;
this may virtually change the height of the element for inview testing.

### InViewContainer

Use `in-view-container` when you have a scollable container that contains `in-view`
elements. When an `in-view` element is inside such container, it will properly
trigger callbacks when the container scrolls as well as when the window scrolls.

```
<div style="height: 150px; overflow-y: scroll; position: fixed;" in-view-container>
	<div style="height:300px" in-view="{expression using $inview}"></li>
</div>
```

## License

MIT
