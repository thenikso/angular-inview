# #Angular-Inview
# - Author: [Nicola Peduzzi](https://github.com/thenikso)
# - Repository: https://github.com/thenikso/angular-inview
# - Install with: `bower install angular-inview`
# - Version: **1.5.0**

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
	# <any in-view="{expression}" [in-view-options="{object}"]></any>
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
				customDebouncedCheck: null
				# In the callback expression, the following variables will be provided:
				# - `$event`: the DOM event that triggered the inView callback.
				# The inView DOM element will be passed in `$event.inViewTarget`.
				# - `$inview`: boolean indicating if the element is in view
				# - `$inviewpart`: string either 'top', 'bottom' or 'both'
				callback: ($event={}, $inview, $inviewpart) -> scope.$evalAsync =>
					$event.inViewTarget = element[0]
					inViewFunc scope,
						'$event': $event
						'$inview': $inview
						'$inviewpart': $inviewpart
			# An additional `in-view-options` attribute can be specified to set offsets
			# that will displace the inView calculation and a debounce to slow down updates
			# via scrolling events.
			if attrs.inViewOptions? and options = scope.$eval(attrs.inViewOptions)
				item.offset = options.offset || [options.offsetTop or 0, options.offsetBottom or 0]
				if options.debounce
					item.customDebouncedCheck = debounce ((event) -> checkInView [item], element[0], event), options.debounce
			# A series of checks are set up to verify the status of the element visibility.
			performCheck = item.customDebouncedCheck ? containerController?.checkInView ? windowCheckInView
			if containerController?
				containerController.addItem item
			else
				addWindowInViewItem item
			# This checks will be performed immediatly and when a relevant measure changes.
			setTimeout performCheck
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
			@checkInView = (event) =>
				i.customDebouncedCheck() for i in @items when i.customDebouncedCheck?
				checkInView (i for i in @items when not i.customDebouncedCheck?), $element[0], event
			@
		]
		# Custom checks on child `in-view` elements will be triggered when the
		# `in-view-container` scrolls.
		link: (scope, element, attrs, controller) ->
			element.bind 'scroll', controller.checkInView
			trackInViewContainer controller
			scope.$on '$destroy', ->
				element.unbind 'scroll', controller.checkInView
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
windowEventsHandler = (event) ->
	c.checkInView(event) for c in _containersControllers
	windowCheckInView(event) if _windowInViewItems.length
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
triggerInViewCallback = (event, item, inview, isTopVisible, isBottomVisible) ->
	if inview
		elOffsetTop = getBoundingClientRect(item.element[0]).top + window.pageYOffset
		inviewpart = (isTopVisible and isBottomVisible and 'neither') or (isTopVisible and 'top') or (isBottomVisible and 'bottom') or 'both'
		# The callback will be called only if a relevant value has changed.
		# However, if the element changed it's position (for example if it has been
		# pushed down by dynamically loaded content), the callback will be called anyway.
		unless item.wasInView and item.wasInView == inviewpart and elOffsetTop == item.lastOffsetTop
			item.lastOffsetTop = elOffsetTop
			item.wasInView = inviewpart
			item.callback event, yes, inviewpart
	else if item.wasInView
		item.wasInView = no
		item.callback event, no

# The main function to check if the given items are in view relative to the provided container.
checkInView = (items, container, event) ->
	# It first calculate the viewport.
	viewport =
		top: 0
		bottom: getViewportHeight()
	# Restrict viewport if a container is specified.
	if container and container isnt window
		bounds = getBoundingClientRect container
		# Shortcut to all item not in view if container isn't itself.
		if bounds.top > viewport.bottom or bounds.bottom < viewport.top
			triggerInViewCallback(event, item, false) for item in items
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
		boundsTop = bounds.top + if offsetIsPercentage(item.offset) then getOffsetFromPercentage(bounds, item.offset) else parseInt(item.offset?[0] ? item.offset)
		boundsBottom = bounds.bottom + if offsetIsPercentage(item.offset) then getOffsetFromPercentage(bounds, item.offset) else parseInt(item.offset?[1] ? item.offset)
		# Calculate parts in view.
		if boundsTop < viewport.bottom and boundsBottom >= viewport.top
			triggerInViewCallback(event, item, true, boundsBottom > viewport.bottom, boundsTop < viewport.top)
		else
			triggerInViewCallback(event, item, false)

# ### Utility functions

# Checks if the provided offset value is a percentage or not
offsetIsPercentage = (offset) ->
	typeof offset is 'string' and offset.slice(-1) is '%'

# Calculates the offset in pixels based on the percentage provided
getOffsetFromPercentage = (bounds, offsetPercentage) ->
	percentage = offsetPercentage.substring 0, offsetPercentage.length - 1
	(bounds.bottom - bounds.top) *  (percentage / 100)

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
	(args...)->
		clearTimeout timer if timer?
		timer = setTimeout (-> f(args...)), (t ? 100)

# The main funciton to perform in-view checks on all items.
windowCheckInView = (event) ->
	i.customDebouncedCheck() for i in _windowInViewItems when i.customDebouncedCheck?
	checkInView (i for i in _windowInViewItems when not i.customDebouncedCheck?), null, event
