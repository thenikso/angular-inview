'use strict';

describe("angular-inview", function() {

	var $rootScope, $compile, $q;

	beforeEach(function () {
		module('angular-inview');

		inject(function (_$rootScope_, _$compile_, _$q_) {
			$rootScope = _$rootScope_;
			$compile = _$compile_;
			$q = _$q_;
		});
	});

	describe("in-view directive", function() {

		it("should trigger in-view expression with `$inview` local", function(done) {
			var test = makeTestForHtml(
				'<div in-view="spy($inview)"></div>'
			);
			scrollTo(0)
			.then(function () {
				expect(test.spy.calls.count()).toBe(1);
				expect(test.spy).toHaveBeenCalledWith(true);
			})
			.then(done);
		});

		it("should not trigger in-view expression if out of viewport", function(done) {
			var test = makeTestForHtml(
				'<div in-view="spy($inview)" style="margin-top:-100px"></div>'
			);
			scrollTo(0)
			.then(function () {
				expect(test.spy.calls.count()).toBe(0);
			})
			.then(done);
		});

	});

	// A test object has the properties:
	//
	//  - `element`: An angular element inserted in the test page
	//  - `scope`: a new isolated scope that can be referenced in the element
	//  - `spy`: a conveninence jasmine spy attached to the scope as `spy`
	function makeTestForHtml(html) {
		var test = {};
		// Prepare test elements
		window.document.body.style.height = '100%';
		window.document.body.parentElement.style.height = '100%';
		test.element = angular.element(html);
		angular.element(window.document.body).empty().append(test.element);
		// Prepare test scope
		test.scope = $rootScope.$new(true);
		test.spy = test.scope.spy = jasmine.createSpy('spy');
		// Compile the element
		$compile(test.element)(test.scope);
		test.scope.$digest();
		return test;
	}

	// Scrolls the element to the given x, y position and waits a bit before
	// resolving the returned promise.
	function scrollTo(element, position) {
		if (!angular.isDefined(position)) {
			position = element;
			element = window;
		}
		if (!angular.isArray(position)) {
			position = [0, position];
		}
		if (element === window) {
			element.scrollTo.apply(element, position);
		}
		else {
			element.scrollLeft += position[0];
			element.scrollTop += position[1];
		}
		var q = $q(function (resolve, reject) {
			setTimeout(function () {
				resolve();
				$rootScope.$digest();
			}, 2);
		});
		return q;
	}

});
