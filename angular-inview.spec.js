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
			makeTestForHtml(
				'<div in-view="spy($inview)"></div>'
			)
			.then(function (test) {
				expect(test.spy.calls.count()).toBe(1);
				expect(test.spy).toHaveBeenCalledWith(true);
			})
			.then(done);
		});

		it("should not trigger in-view expression if out of viewport", function(done) {
			makeTestForHtml(
				'<div in-view="spy($inview)" style="margin-top:-100px"></div>'
			)
			.then(function (test) {
				expect(test.spy.calls.count()).toBe(0);
			})
			.then(done);
		});

		it("should change inview status when scrolling out of view", function(done) {
			makeTestForHtml(
				'<div in-view="spy($inview)"></div>' +
				'<div style="height:200%"></div>'
			)
			.then(lazyScrollTo(100))
			.then(function (test) {
				expect(test.spy.calls.count()).toBe(2);
				expect(test.spy).toHaveBeenCalledWith(true);
				expect(test.spy).toHaveBeenCalledWith(false);
			})
			.then(done);
		});

		describe("informations object", function() {

			it("should return an info object with relative informations", function(done) {
				makeTestForHtml(
					'<div in-view="spy($inviewInfo)"></div>'
				)
				.then(function (test) {
					expect(test.spy.calls.count()).toBe(1);
					var info = test.spy.calls.mostRecent().args[0];
					expect(info.inView).toEqual(true);
					expect(info.parts).toEqual({
						top: true,
						left: true,
						bottom: true,
						right: true
					});
				})
				.then(done);
			});

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
		return scrollTo(window, [0, 0]).then(function () {
			return test;
		});
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
		// Prepare promise resolution
		var deferred = $q.defer(), timeout;
		var scrollOnceHandler = function () {
			var check = (element === window) ?
				[element.scrollX, element.scrollY] :
				[element.scrollLeft, element.scrollTop];
			if (check[0] != position[0] || check[1] != position[1]) {
				return;
			}
			if (timeout) {
				clearTimeout(timeout);
				timeout = null;
			}
			angular.element(element).off('scroll', scrollOnceHandler);
			deferred.resolve();
			$rootScope.$digest();
		};
		angular.element(element).on('scroll', scrollOnceHandler);
		// Actual scrolling
		if (element === window) {
			element.scrollTo.apply(element, position);
		}
		else {
			element.scrollLeft += position[0];
			element.scrollTop += position[1];
		}
		// Backup resolver
		timeout = setTimeout(function () {
			angular.element(element).off('scroll', scrollOnceHandler);
			var check = (element === window) ?
				[element.scrollX, element.scrollY] :
				[element.scrollLeft, element.scrollTop];
			if (check[0] != position[0] || check[1] != position[1]) {
				deferred.reject();
			}
			else {
				deferred.resolve();
			}
			$rootScope.$digest();
		}, 100);
		return deferred.promise;
	}

	function lazyScrollTo () {
		var args = arguments;
		return function (x) {
			return scrollTo.apply(null, args).then(function () {
				return x;
			});
		}
	}

});
