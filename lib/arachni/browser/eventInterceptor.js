
// Avoid overriding the overrides in case this gets included in AJAX responses
// and other dynamic stuff.
if( _token_eventsPerElement == null ) {

    // Holds registered events (and their handlers) per their elements.
    var _token_eventsPerElement = {};

    // Install the overrides.
    _token_override_addEventListener();

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
