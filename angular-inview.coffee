'use strict'

# author Nicola Peduzzi
# fork https://github.com/thenikso/angular-inview

angular.module('angular-inview', [])

	# inViewContainer
	.directive 'inViewContainer', ->
		restrict: 'AC'
		controller: ->
			@items = []
			@addItem = (item) ->
				@items.push item
			@removeItem = (item) ->
				@items = (i for i in @items when i isnt item)
			@
		link: (scope, element, attrs, controller) ->
			check = debounce -> checkInView controller.items
			element.bind 'scroll', check
			scope.$on '$destroy', ->
				element.unbind 'scroll', check

	# inView
	# Evaluate the expression passet to the attribute `in-view` when the DOM
	# element is visible in the viewport.
	# In the expression the following variables will be provided:
	# 	$inview: boolean indicating if the element is in view
	# 	$inviewpart: string either 'top', 'bottom' or 'both'
	# An additional `in-view-offset` attribute can be specified to set an offset
	# that will displace the inView calculation.
	# Usage:
	# <any in-view="{expression}" [in-view-offset="{number}"]></any>
	.directive 'inView', ['$parse', ($parse) ->
		restrict: 'A'
		require: '?^inViewContainer'
		link: (scope, element, attrs, container) ->
			return unless attrs.inView
			inViewFunc = $parse(attrs.inView)
			item =
				element: element
				wasInView: no
				offset: 0
				callback: ($inview, $inviewpart) -> scope.$apply =>
					inViewFunc scope,
						'$element': element[0]
						'$inview': $inview
						'$inviewpart': $inviewpart
			container?.addItem item
			if attrs.inViewOffset?
				attrs.$observe 'inViewOffset', (offset) ->
					unless angular.isNumber offset
						offset = parseInt offset
						offset = 0 if isNaN offset
					item.offset = offset
					do checkInViewDebounced
			addInViewItem item
			do checkInViewDebounced
			scope.$on '$destroy', ->
				container?.removeItem item
				removeInViewItem item
	]

getViewportHeight = ->
	height = window.innerHeight
	return height if height

	mode = document.compatMode

	if mode or not $?.support?.boxModel
		height = if mode is 'CSS1Compat' then document.documentElement.clientHeight else document.body.clientHeight

	height

offsetTop = (el) ->
	result = 0
	parent = el.parentElement
	while el
		result += el.offsetTop
		el = el.offsetParent
	while parent
		result -= parent.scrollTop if parent.scrollTop?
		parent = parent.parentElement
	result

# Object items are:
# {
# 	element: <angular.element>,
# 	offset: <number>,
# 	wasInView: <bool>,
# 	callback: <funciton taking 2 parameters: $inview and $inviewpart>
# }
_checkInViewItems = []
addInViewItem = (item) ->
	if _checkInViewItems.length is 0
		angular.element(window).bind 'checkInView click ready scroll resize', checkInViewDebounced
	_checkInViewItems.push item
removeInViewItem = (item) ->
	_checkInViewItems = (i for i in _checkInViewItems when i isnt item)
	if _checkInViewItems.length is 0
		angular.element(window).unbind 'checkInView click ready scroll resize', checkInViewDebounced

checkInView = (items) ->
	viewportTop = 0
	viewportBottom = viewportTop + getViewportHeight()

	for item in items
		elementTop = offsetTop(item.element[0]) + (item.offset ? 0)
		elementHeight = item.element[0].offsetHeight
		elementBottom = elementTop + elementHeight
		inView = elementTop > viewportTop and elementBottom < viewportBottom
		isBottomVisible = elementBottom > viewportTop and elementTop < viewportTop
		isTopVisible = elementTop < viewportBottom and elementBottom > viewportBottom
		inViewWithOffset = inView or isBottomVisible or isTopVisible or (elementTop < viewportTop and elementBottom > viewportBottom)
		if inViewWithOffset
			inviewpart = (isTopVisible and 'top') or (isBottomVisible and 'bottom') or 'both'
			unless item.wasInView and item.wasInView == inviewpart
				item.wasInView = inviewpart
				item.callback yes, inviewpart
		else if not inView and item.wasInView
			item.wasInView = no
			item.callback no

debounce = (f, t) ->
	timer = null
	->
		clearTimeout timer if timer?
		timer = setTimeout f, (t ? 100)

checkInViewDebounced = debounce -> checkInView _checkInViewItems
