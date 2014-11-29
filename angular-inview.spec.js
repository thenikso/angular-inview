'use strict';

describe("angular-inview", function() {

	beforeEach(function () {
		module('angular-inview');

		inject(function (_$rootScope_, _$compile_) {
			makeTestForHtml.$rootScope = _$rootScope_;
			makeTestForHtml.$compile = _$compile_;
		});
	});

	it("should trigger in-view expression with `$inview` local", function() {
		var test = makeTestForHtml(
			'<div in-view="spy($inview)"></div>'
		);
		expect(test.spy).toHaveBeenCalledWith(true);
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
		test.scope = makeTestForHtml.$rootScope.$new(true);
		test.spy = test.scope.spy = jasmine.createSpy('spy');
		// Compile the element
		makeTestForHtml.$compile(test.element)(test.scope);
		test.scope.$digest();
		return test;
	}

});
