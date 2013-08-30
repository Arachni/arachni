
 /*
  * Allows the system to optimize DOM/JS/AJAX analysis by overriding JS prototypes
  * and tracking things like bound events and timers.
 */

// Avoid overriding the overrides in case this gets included in AJAX responses
// and other dynamic stuff.
if( _token_initialized == null ) {
    var _token_initialized = true;

    // Holds registered events (and their handlers) per their elements.
    var _token_eventsPerElement = {};

    // Keeps track of setTimeout() calls.
    var _token_setTimeouts = [];

    // Keeps track of setInterval() calls.
    var _token_setIntervals = [];

    // Install the overrides.
    _token_override();
    function _token_override() {
        _token_override_setTimeout();
        _token_override_setInterval();
        _token_override_addEventListener();
    }

    // Override setInterval() so that we'll know to wait for it to be triggered
    // during DOM analysis to provide sufficient coverage.
    function _token_override_setInterval() {
        var _token_original_setInterval = window.setInterval;
        window.setInterval = function( func, delay ) {
            _token_setIntervals.push( [func, delay] );
            _token_original_setInterval( func, delay );
        };
    }

    // Override setTimeout() so that we'll know to wait for it to be triggered
    // during DOM analysis to provide sufficient coverage.
    function _token_override_setTimeout() {
        var _token_original_setTimeout = window.setTimeout;
        window.setTimeout = function( func, delay ) {
            _token_setTimeouts.push( [func, delay] );
            _token_original_setTimeout( func, delay );
        };
    }

    // Overrides window.addEventListener and Node.prototype.addEventListener
    // to intercept event binds so that we can keep track of them in order to
    // optimize DOM analysis.
    function _token_override_addEventListener() {
        // Override window.addEventListener
        var _token_original_Window_addEventListener = window.addEventListener;
        window.addEventListener = function _window_addEventListener( event, listener, useCapture ) {
            _token_registerEvent( window, event, listener );
            _token_original_Window_addEventListener.apply( window, [].slice.call( arguments ) );
        };

        // Override Node.prototype.addEventListener
        var _token_original_Node_addEventListener = Node.prototype.addEventListener;
        Node.prototype.addEventListener = function _Node_addEventListener( event, listener, useCapture ) {
            _token_registerEvent( this, event, listener );
            _token_original_Node_addEventListener.apply( this, [].slice.call( arguments ) );
        };

        // Provide a method to retrieve the events for each Node.
        Node.prototype.events = function () { return _token_getEvents( this ); }
    }

    // Registers an event and its handler for the given element.
    function _token_registerEvent( element, event, handler ) {
        if( !(element in _token_eventsPerElement) ) _token_eventsPerElement[element] = [];
        _token_eventsPerElement[element].push( [event, handler] );
    }

    // Returns all events and their handlers for the given element.
    function _token_getEvents( element ) {
        if( !(element in _token_eventsPerElement) ) return [];
        return _token_eventsPerElement[element];
    }
}
