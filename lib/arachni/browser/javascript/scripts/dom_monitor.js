/*
 * Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
 * All rights reserved.
 */

/*
 * Allows the system to optimize DOM/JS/AJAX analysis by overriding JS prototypes
 * and tracking things like bound events and timers.
 */
var _tokenDOMMonitor = _tokenDOMMonitor || {

    // Signals that our custom monitoring overrides have already been installed
    // for this document.
    initialized:       false,

    // Holds registered events and their handlers, as added via addEventListener,
    // for each element.
    eventsPerElement: {},

    // Keeps track of setTimeout() calls.
    setTimeouts:      [],

    // Keeps track of setInterval() calls.
    setIntervals:     [],

    // Initialize.
    initialize: function () {
        if( _tokenDOMMonitor.initialized ) return;

        _tokenDOMMonitor.override_setTimeout();
        _tokenDOMMonitor.override_setInterval();
        _tokenDOMMonitor.override_addEventListener();

        _tokenDOMMonitor.initialized = true
    },

    // Override setInterval() so that we'll know to wait for it to be triggered
    // during DOM analysis to provide sufficient coverage.
    override_setInterval: function () {
        var original_setInterval = window.setInterval;

        window.setInterval = function() {
            _tokenDOMMonitor.setIntervals.push( arguments );
            original_setInterval.apply( this, arguments );
        };
    },

    // Override setTimeout() so that we'll know to wait for it to be triggered
    // during DOM analysis to provide sufficient coverage.
    override_setTimeout: function () {
        var original_setTimeout = window.setTimeout;

        window.setTimeout = function() {
            _tokenDOMMonitor.setTimeouts.push( arguments );
            original_setTimeout.apply( this, arguments );
        };
    },

    // Overrides window.addEventListener and Node.prototype.addEventListener
    // to intercept event binds so that we can keep track of them in order to
    // optimize DOM analysis.
    override_addEventListener: function () {
        // Override window.addEventListener
        var original_Window_addEventListener = window.addEventListener;

        window.addEventListener = function _window_addEventListener( event, listener, useCapture ) {
            _tokenDOMMonitor.registerEvent( window, event, listener );
            original_Window_addEventListener.apply( window, [].slice.call( arguments ) );
        };

        // Override Node.prototype.addEventListener
        var original_Node_addEventListener = Node.prototype.addEventListener;

        Node.prototype.addEventListener = function _Node_addEventListener( event, listener, useCapture ) {
            _tokenDOMMonitor.registerEvent( this, event, listener );
            original_Node_addEventListener.apply( this, [].slice.call( arguments ) );
        };

        // Provide a method to retrieve the events for each Node.
        Node.prototype.events = function () { return _tokenDOMMonitor.getEvents( this ); }
    },

    // Registers an event and its handler for the given element.
    registerEvent: function ( element, event, handler ) {
        if( !(element in _tokenDOMMonitor.eventsPerElement) ) _tokenDOMMonitor.eventsPerElement[element] = [];

        _tokenDOMMonitor.eventsPerElement[element].push( [event, handler] );
    },

    // Returns all events and their handlers for the given element.
    getEvents: function ( element ) {
        if( !(element in _tokenDOMMonitor.eventsPerElement) ) return [];

        return _tokenDOMMonitor.eventsPerElement[element];
    }
};
