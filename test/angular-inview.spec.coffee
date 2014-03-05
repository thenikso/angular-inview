'use strict'

createTestView = (elemHtml, bef, aft) ->
	test =
		elem: null
		scope: null

	beforeEach inject ($rootScope, $compile) ->
		# Prepare test element
		test.elem = angular.element elemHtml
		$('body,html').css('height', '100%');
		$('body').append test.elem
		# Prepare test object
		test.scope = $rootScope.$new(yes)
		test.scope.inviewSpy = jasmine.createSpy 'inviewSpy'
		test.spyCalls = 0
		test.scrollAndWaitInView = (scroll, callback) ->
			test.spyCalls = test.scope.inviewSpy.calls.length
			scroll?() ? $(window).scrollTop scroll
			waitsFor (-> test.scope.inviewSpy.calls.length > test.spyCalls), 'Scrolling should trigger an in view', 500
			if callback? then runs -> callback()
		# Compile
		$compile(test.elem) test.scope
		test.scope.$digest()
		# Wait for scrolling
		bef?()
		test.scrollAndWaitInView(0)

	afterEach ->
		test.scope?.$destroy()
		test.scope = null
		test.elem?.remove()
		test.elem = null
		aft?()

	test

describe 'Directive: inView', ->
	beforeEach module 'angular-inview'

	test = createTestView """
		<div id="zero" in-view="inviewSpy(0, $inview, $inviewpart)" style="height:0"></div>
		<div id="one" in-view="inviewSpy(1, $inview, $inviewpart)" style="height:100%">one</div>
		<div id="two" in-view="inviewSpy(2, $inview, $inviewpart)" style="height:100%" in-view-offset="{{twoOffset}}">two</div>
		<div id="three" in-view="inviewSpy(3, $inview, $inviewpart)" in-view-offset="{{threeOffset}}" style="height:100%">three</div>
	"""

	it 'should initially execute the expression only for visible elements', ->
		runs ->
			expect(test.scope.inviewSpy.calls.length).toEqual(2)
			expect(test.scope.inviewSpy).toHaveBeenCalledWith(0, true, 'both')
			expect(test.scope.inviewSpy).toHaveBeenCalledWith(1, true, 'top')

	it 'should change the inview status on scrolling', ->
		test.scrollAndWaitInView window.innerHeight / 2, ->
			expect(test.scope.inviewSpy.calls.length - test.spyCalls).toEqual(3)
			expect(test.scope.inviewSpy).toHaveBeenCalledWith(0, false, undefined)
			expect(test.scope.inviewSpy).toHaveBeenCalledWith(1, true, 'bottom')
			expect(test.scope.inviewSpy).toHaveBeenCalledWith(2, true, 'top')

			test.scrollAndWaitInView window.innerHeight * 2, ->
				expect(test.scope.inviewSpy.calls.length - test.spyCalls).toEqual(3)
				expect(test.scope.inviewSpy).toHaveBeenCalledWith(1, false, undefined)
				expect(test.scope.inviewSpy).toHaveBeenCalledWith(2, true, 'bottom')
				expect(test.scope.inviewSpy).toHaveBeenCalledWith(3, true, 'top')

	it 'should consider offset', ->
		test.scope.twoOffset = window.innerHeight
		test.scope.$digest()
		test.scrollAndWaitInView window.innerHeight / 2, ->
			expect(test.scope.inviewSpy).not.toHaveBeenCalledWith(2, true, 'top')

			test.scrollAndWaitInView window.innerHeight * 2, ->
				expect(test.scope.inviewSpy).toHaveBeenCalledWith(2, true, 'top')

describe 'Directive: inViewContainer', ->
	beforeEach module 'angular-inview'

	test = createTestView """
		<div id="container1" in-view-container style="height:100%">
			<div id="c1zero" in-view="inviewSpy(10, $inview, $inviewpart)" style="height:0"></div>
			<div id="c1one" in-view="inviewSpy(11, $inview, $inviewpart)" style="height:100%">one</div>
			<div id="c1two" in-view="inviewSpy(12, $inview, $inviewpart)" style="height:100%">two</div>
			<div id="container2" in-view-container style="height:100%;overflow:scroll;">
				<div id="c2zero" in-view="inviewSpy(20, $inview, $inviewpart)" style="height:0"></div>
				<div id="c2one" in-view="inviewSpy(21, $inview, $inviewpart)" style="height:100%">one</div>
				<div id="c2two" in-view="inviewSpy(22, $inview, $inviewpart)" style="height:100%">two</div>
			</div>
			<div id="c1three" in-view="inviewSpy(13, $inview, $inviewpart)" in-view-offset="{{threeOffset}}" style="height:100%">three</div>
		</div>
	""", ->
		test.elem2 = test.elem.find('#container2')

	it 'should fire inview with windows scroll', ->
		test.scrollAndWaitInView window.innerHeight * 2, ->
			expect(test.scope.inviewSpy.calls.length).toEqual(2 + 5)
			expect(test.scope.inviewSpy).toHaveBeenCalledWith(12, true, 'bottom')
			expect(test.scope.inviewSpy).toHaveBeenCalledWith(20, true, 'both')
			expect(test.scope.inviewSpy).toHaveBeenCalledWith(21, true, 'top')

	it 'should trigger inview with container scroll for all nested children', ->
		test.scrollAndWaitInView (->
			$(window).scrollTop window.innerHeight * 2
			test.elem2.scrollTop window.innerHeight
			), ->
				expect(test.scope.inviewSpy.calls.length).toEqual(2 + 5)
				expect(test.scope.inviewSpy).toHaveBeenCalledWith(12, true, 'bottom')
				expect(test.scope.inviewSpy).toHaveBeenCalledWith(21, true, 'bottom')
				expect(test.scope.inviewSpy).toHaveBeenCalledWith(22, true, 'top')

