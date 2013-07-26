'use strict'

describe 'Directive: inView', ->
	beforeEach module 'angular-inview'

	elem = null
	scope = null
	beforeEach inject ($rootScope, $compile) ->
		elem = angular.element "
			<div id=\"zero\" in-view=\"inviewSpy(0, $inview, $inviewpart)\" style=\"height:0\"></div>
			<div id=\"one\" in-view=\"inviewSpy(1, $inview, $inviewpart)\" style=\"height:100%\">one</div>
			<div id=\"two\" in-view=\"inviewSpy(2, $inview, $inviewpart)\" style=\"height:100%\">two</div>
			<div id=\"three\" in-view=\"inviewSpy(3, $inview, $inviewpart)\" in-view-offset=\"{{threeOffset}}\" style=\"height:100%\">three</div>
		"
		$('body,html').css('height', '100%');
		$('body').append elem
		window.scrollTo 0, 0

		scope = $rootScope.$new(yes)
		scope.inviewSpy = jasmine.createSpy 'inviewSpy'
		$compile(elem) scope
		scope.$digest()

		waitsFor (-> scope.inviewSpy.wasCalled), 'At least one in-vew should fire', 500

	afterEach ->
		scope?.$destroy()
		scope = null
		elem?.remove()
		elem = null

	it 'should initially execute the expression only for inview elements', ->
		runs ->
			expect(scope.inviewSpy.calls.length).toEqual(2)
			expect(scope.inviewSpy).toHaveBeenCalledWith(0, true, 'both')
			expect(scope.inviewSpy).toHaveBeenCalledWith(1, true, 'top')

	it 'should change the inview status on scrolling', ->
		spyCalls = scope.inviewSpy.calls.length
		$(window).scrollTop window.innerHeight / 2
		waitsFor (-> scope.inviewSpy.calls.length > spyCalls), 'Scrolling should trigger an in view', 500
		runs ->
			expect(scope.inviewSpy.calls.length - spyCalls).toEqual(3)
			expect(scope.inviewSpy).toHaveBeenCalledWith(0, false, undefined)
			expect(scope.inviewSpy).toHaveBeenCalledWith(1, true, 'bottom')
			expect(scope.inviewSpy).toHaveBeenCalledWith(2, true, 'top')

			spyCalls = scope.inviewSpy.calls.length
			$(window).scrollTop window.innerHeight * 2
			waitsFor (-> scope.inviewSpy.calls.length > spyCalls), 'Scrolling should trigger an in view', 500
			runs ->
				expect(scope.inviewSpy.calls.length - spyCalls).toEqual(3)
				expect(scope.inviewSpy).toHaveBeenCalledWith(1, false, undefined)
				expect(scope.inviewSpy).toHaveBeenCalledWith(2, true, 'bottom')
				expect(scope.inviewSpy).toHaveBeenCalledWith(3, true, 'top')
