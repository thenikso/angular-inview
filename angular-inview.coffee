# #Angular-Inview
# - Author: [Nicola Peduzzi](https://github.com/thenikso)
# - Repository: https://github.com/thenikso/angular-inview

'use strict'

# An [angular.js](https://angularjs.org) directive to evaluate an expression if
# a DOM element is or not in the current visible browser viewport.
# Use it in your Angular.js app by including the javascript and requireing it:
#
# `angular.module('myApp', ['angular-inview'])`
angular.module('angular-inview', [])

	# ##in-view directive
	#
	# **Usage**
	# ```html
	# <any in-view="{expression}" [in-view-offset="{number|array}"]></any>
	# ```
	.directive 'inView', ['$parse', ($parse) ->
		# Evaluate the expression passet to the attribute `in-view` when the DOM
		# element is visible in the viewport.
		restrict: 'A'
		# If the `in-view` element is contained in a scrollable view other than the
		# window, that containing element should be [marked as a container](#in-view-container-directive).
		require: '?^inViewContainer'
		link: (scope, element, attrs, containerController) ->
			return unless attrs.inView
			inViewFunc = $parse(attrs.inView)
			item =
				element: element
				wasInView: no
				offset: 0
				# In the callback expression, the following variables will be provided:
				# - `$element`: the DOM element
				# - `$inview`: boolean indicating if the element is in view
				# - `$inviewpart`: string either 'top', 'bottom' or 'both'
				callback: ($inview, $inviewpart) -> scope.$apply =>
					inViewFunc scope,
						'$element': element[0]
						'$inview': $inview
						'$inviewpart': $inviewpart
			# An additional `in-view-offset` attribute can be specified to set an offset
			# that will displace the inView calculation.
			if attrs.inViewOffset?
				attrs.$observe 'inViewOffset', (offset) ->
					item.offset = scope.$eval(offset) or 0
					do performCheckDebounced
			# A series of checks are set up to verify the status of the element visibility.
			performCheckDebounced = windowCheckInViewDebounced
			if containerController?
				containerController.addItem item
				performCheckDebounced = containerController.checkInViewDebounced
			else
				addWindowInViewItem item
			# This checks will be performed immediatly and when a relevant measure changes.
			do performCheckDebounced
			# When the element is removed, all the logic behind in-view is removed.
			# One might want to use `in-view` in conjunction with `ng-if` when using
			# the directive for lazy loading.
			scope.$on '$destroy', ->
				containerController?.removeItem item
				removeWindowInViewItem item
	]

	# ## in-view-container directive
	.directive 'inViewContainer', ->
		# Use this as an attribute or a class to mark a scrollable container holding
		# `in-view` directives as children.
		restrict: 'AC'
		# This directive will track child `in-view` elements.
		controller: ['$element', ($element) ->
			@items = []
			@addItem = (item) ->
				@items.push item
			@removeItem = (item) ->
				@items = (i for i in @items when i isnt item)
			@checkInViewDebounced = debounce =>
				checkInView @items, $element[0]
			@
		]
		# Custom checks on child `in-view` elements will be triggered when the
		# `in-view-container` scrolls.
		link: (scope, element, attrs, controller) ->
			element.bind 'scroll', controller.checkInViewDebounced
			trackInViewContainer controller
			scope.$on '$destroy', ->
				element.unbind 'scroll', controller.checkInViewDebounced
				untrackInViewContainer controller

# ## Utilities

# ### items management

# The collectin of all in-view items. Items are object with the structure:
# ```
# {
# 	element: <angular.element>,
# 	offset: <number>,
# 	wasInView: <bool>,
# 	callback: <funciton>
# }
# ```
_windowInViewItems = []
addWindowInViewItem = (item) ->
	_windowInViewItems.push item
	do bindWindowEvents
removeWindowInViewItem = (item) ->
	_windowInViewItems = (i for i in _windowInViewItems when i isnt item)
	do unbindWindowEvents

# List of containers controllers
_containersControllers = []
trackInViewContainer = (controller) ->
	_containersControllers.push controller
	do bindWindowEvents
untrackInViewContainer = (container) ->
	_containersControllers = (c for c in _containersControllers when c isnt container)
	do unbindWindowEvents

# ### Events handler management
_windowEventsHandlerBinded = no
windowEventsHandler = ->
	do c.checkInViewDebounced for c in _containersControllers
	do windowCheckInViewDebounced if _windowInViewItems.length
bindWindowEvents = ->
	# The bind to window events will be added only if actually needed.
	return if _windowEventsHandlerBinded
	_windowEventsHandlerBinded = yes
	angular.element(window).bind 'checkInView click ready scroll resize', windowEventsHandler
unbindWindowEvents = ->
	# All the window bindings will be removed if no directive requires to be checked.
	return unless _windowEventsHandlerBinded
	return if _windowInViewItems.length or _containersControllers.length
	_windowEventsHandlerBinded = no
	angular.element(window).unbind 'checkInView click ready scroll resize', windowEventsHandler

# ### InView checks
# This method will call the user defined callback with the proper parameters if neccessary.
triggerInViewCallback = (item, inview, isTopVisible, isBottomVisible) ->
	if inview
		elOffsetTop = getBoundingClientRect(item.element[0]).top + window.pageYOffset
		inviewpart = (isTopVisible and 'top') or (isBottomVisible and 'bottom') or 'both'
		# The callback will be called only if a relevant value has changed.
		# However, if the element changed it's position (for example if it has been
		# pushed down by dynamically loaded content), the callback will be called anyway.
		unless item.wasInView and item.wasInView == inviewpart and elOffsetTop == item.lastOffsetTop
			item.lastOffsetTop = elOffsetTop
			item.wasInView = inviewpart
			item.callback yes, inviewpart
	else if item.wasInView
		item.wasInView = no
		item.callback no

# The main function to check if the given items are in view relative to the provided container.
checkInView = (items, container) ->
	# It first calculate the viewport.
	viewport =
		top: 0
		bottom: getViewportHeight()
	# Restrict viewport if a container is specified.
	if container and container isnt window
		bounds = getBoundingClientRect container
		# Shortcut to all item not in view if container isn't itself.
		if bounds.top > viewport.bottom or bounds.bottom < viewport.top
			triggerInViewCallback(item, false) for item in items
			return
		# Actual viewport restriction.
		viewport.top = bounds.top if bounds.top > viewport.top
		viewport.bottom = bounds.bottom if bounds.bottom < viewport.bottom
	# Calculate inview status for each item.
	for item in items
		# Get the bounding top and bottom of the element in the viewport.
		element = item.element[0]
		bounds = getBoundingClientRect element
		# Apply offset.
		boundsTop = bounds.top + parseInt(item.offset?[0] ? item.offset)
		boundsBottom = bounds.bottom + parseInt(item.offset?[1] ? item.offset)
		# Calculate parts in view.
		if boundsTop < viewport.bottom and boundsBottom >= viewport.top
			triggerInViewCallback(item, true, boundsBottom > viewport.bottom, boundsTop < viewport.top)
		else
			triggerInViewCallback(item, false)

# ### Utility functions

# Returns the height of the window viewport
getViewportHeight = ->
	height = window.innerHeight
	return height if height
	mode = document.compatMode
	if mode or not $?.support?.boxModel
		height = if mode is 'CSS1Compat' then document.documentElement.clientHeight else document.body.clientHeight
	height

# Polyfill for `getBoundingClientRect`
getBoundingClientRect = (element) ->
	return element.getBoundingClientRect() if element.getBoundingClientRect?
	top = 0
	el = element
	while el
		top += el.offsetTop
		el = el.offsetParent
	parent = element.parentElement
	while parent
		top -= parent.scrollTop if parent.scrollTop?
		parent = parent.parentElement
	return {
		top: top
		bottom: top + element.offsetHeight
	}

# Debounce a function.
debounce = (f, t) ->
	timer = null
	->
		clearTimeout timer if timer?
		timer = setTimeout f, (t ? 100)

# The main funciton to perform in-view checks on all items.
windowCheckInViewDebounced = debounce -> checkInView _windowInViewItems
