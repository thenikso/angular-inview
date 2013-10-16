'use strict'

# author Nicola Peduzzi
# fork https://github.com/thenikso/angular-inview

angular.module('angular-inview', [])

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
	.directive 'inView', ($parse)->
		restrict: 'A'
		link: (scope, element, attrs) ->
			return unless attrs.inView
			inViewFunc = $parse(attrs.inView)
			item =
				element: element
				wasInView: no
				offset: 0
				callback: ($inview, $inviewpart) -> scope.$apply ->
					inViewFunc scope,
						'$inview': $inview
						'$inviewpart': $inviewpart
			if attrs.inViewOffset?
				attrs.$observe 'inViewOffset', (offset) ->
					item.offset = offset
					do checkInViewDebounced
			checkInViewItems.push item
			do checkInViewDebounced
			scope.$on '$destroy', ->
				removeInViewItem item

getScrollTop = ->
	window.pageYOffset or document.documentElement.scrollTop or document.body.scrollTop

getViewportHeight = ->
	height = window.innerHeight
	return height if height

	mode = document.compatMode

	if mode or not $?.support?.boxModel
		height = if mode is 'CSS1Compat' then document.documentElement.clientHeight else document.body.clientHeight

	height

offsetTop = (el) ->
	curtop = 0
	while el
		curtop += el.offsetTop
		el = el.offsetParent
	curtop

# Object items are:
# {
# 	element: <angular.element>,
# 	offset: <number>,
# 	wasInView: <bool>,
# 	callback: <funciton taking 2 parameters: $inview and $inviewpart>
# }
checkInViewItems = []
removeInViewItem = (item) ->
	checkInViewItems = checkInViewItems.filter (i) -> i != item

checkInView = ->
	viewportTop = getScrollTop()
	viewportBottom = viewportTop + getViewportHeight()

	for item in checkInViewItems
		elementTop = offsetTop item.element[0]
		elementHeight = item.element[0].offsetHeight
		elementBottom = elementTop + elementHeight
		inView = elementTop > viewportTop and elementBottom < viewportBottom
		isBottomVisible = elementBottom + item.offset > viewportTop and elementTop < viewportTop
		isTopVisible = elementTop - item.offset < viewportBottom and elementBottom > viewportBottom
		inViewWithOffset = inView or isBottomVisible or isTopVisible or (elementTop < viewportTop and elementBottom > viewportBottom)
		if inViewWithOffset
			inviewpart = (isTopVisible and 'top') or (isBottomVisible and 'bottom') or 'both'
			unless item.wasInView and item.wasInView == inviewpart
				item.wasInView = inviewpart
				item.callback yes, inviewpart
		else if not inView and item.wasInView
			item.wasInView = no
			item.callback no

checkInViewDebounced = do ->
	timer = null
	->
		clearTimeout timer if timer?
		timer = setTimeout checkInView, 100

angular.element(window).bind 'checkInView click ready scroll resize', checkInViewDebounced
