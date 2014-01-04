
/*
* Allows the system to optimize DOM/JS/AJAX analysis by overriding JS prototypes
* and tracking things like bound events and timers.
*/

var _token = _token || {

    // Holds registered events (and their handlers) per their elements.
    eventsPerElement: {},

    // Keeps track of setTimeout() calls.
    setTimeouts: [],

    // Keeps track of setInterval() calls.
    setIntervals: [],

    overridden: false,

    enable_debugging: true,

    debugging_data: [],

    sink: [],

    debug: function (){
        if( !_token.enable_debugging ) return;

        _token.debugging_data.push({
            data:  arguments,
            trace: _token.trace()
        })
    },

    send_to_sink: function (){
        _token.sink.push({
            data:  arguments,
            trace: _token.trace()
        })
    },

    flush_sink: function (){
        var a = _token.sink.slice();
        _token.sink = [];
        return a;
    },

    trace: function () {
        var f = arguments.callee.caller.caller,
            trace = [];

        // TODO: Not sure but there's a chance this can go on forever,
        // keep an eye out.
        while( f ) {
            trace.push({
                function:  f,
                arguments: f.arguments
            });

            f = f.caller;
        }

        return trace;
    },

    // Install the overrides.
    override: function () {
        if( _token.overridden ) return;

        _token.override_setTimeout();
        _token.override_setInterval();
        _token.override_addEventListener();

        _token.overridden = true
    },

    // Override setInterval() so that we'll know to wait for it to be triggered
    // during DOM analysis to provide sufficient coverage.
    override_setInterval: function () {
        var original_setInterval = window.setInterval;

        window.setInterval = function() {
            _token.setIntervals.push( arguments );
            original_setInterval.apply( this, arguments );
        };
    },

    // Override setTimeout() so that we'll know to wait for it to be triggered
    // during DOM analysis to provide sufficient coverage.
    override_setTimeout: function () {
        var original_setTimeout = window.setTimeout;

        window.setTimeout = function() {
            _token.setTimeouts.push( arguments );
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
            _token.registerEvent( window, event, listener );
            original_Window_addEventListener.apply( window, [].slice.call( arguments ) );
        };

        // Override Node.prototype.addEventListener
        var original_Node_addEventListener = Node.prototype.addEventListener;

        Node.prototype.addEventListener = function _Node_addEventListener( event, listener, useCapture ) {
            _token.registerEvent( this, event, listener );
            original_Node_addEventListener.apply( this, [].slice.call( arguments ) );
        };

        // Provide a method to retrieve the events for each Node.
        Node.prototype.events = function () { return _token.getEvents( this ); }
    },

    // Registers an event and its handler for the given element.
    registerEvent: function ( element, event, handler ) {
        if( !(element in _token.eventsPerElement) ) _token.eventsPerElement[element] = [];

        _token.eventsPerElement[element].push( [event, handler] );
    },

    // Returns all events and their handlers for the given element.
    getEvents: function ( element ) {
        if( !(element in _token.eventsPerElement) ) return [];

        return _token.eventsPerElement[element];
    }
};

_token.override();
