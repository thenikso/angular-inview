// # Angular-Inview
// - Author: [Nicola Peduzzi](https://github.com/thenikso)
// - Repository: https://github.com/thenikso/angular-inview
// - Install with: `bower install angular-inview`
// - Version: **2.0-alpha1**
(function() {
'use strict';

// An [angular.js](https://angularjs.org) directive to evaluate an expression if
// a DOM element is or not in the current visible browser viewport.
// Use it in your AngularJS app by including the javascript and requireing it:
//
// `angular.module('myApp', ['angular-inview'])`
angular.module('angular-inview', [])

// ## in-view directive
//
// ### Usage
// ```html
// <any in-view="{expression}" [in-view-options="{object}"]></any>
// ```
.directive('inView', ['$parse', inViewDirective])

// ## in-view-container directive
.directive('inViewContainer', inViewContainerDirective);

// ## Implementation
function inViewDirective ($parse) {
}

function inViewContainerDirective () {
}

})();