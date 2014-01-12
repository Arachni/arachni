/*
* Allows the system to optimize DOM/JS/AJAX analysis by overriding JS prototypes
* and tracking things like bound events and timers.
*/

var _token = _token || {

    // Holds registered events and their handlers, as added via addEventListener,
    // for each element.
    eventsPerElement: {},

    // Keeps track of setTimeout() calls.
    setTimeouts: [],

    // Keeps track of setInterval() calls.
    setIntervals: [],

    // Signals that overrides have already been installed for this document.
    overridden: false,

    // Allows the 'debug' function to operate.
    enable_debugging: true,

    // Hold debugging information, usually pushed by the 'debug' function.
    debugging_data: [],

    sink: [],

    taint: null,

    traced: {},

    anonymous_function_names: {},

    debug: function (){
        if( !_token.enable_debugging ) return;

        _token.debugging_data.push({
            data:  arguments,
            trace: _token.trace()
        })
    },

    log_sink: function (){
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

    trace: function ( depth_offset ) {
        var f = arguments.callee,
            trace = [];

        depth_offset = parseInt( depth_offset ) || 3;
        for( var i = 0; i < depth_offset - 1; i++ ) {
            if( f ) f = f.caller;
        }

        var error = _token.get_error_object();
        var stackArrayOffset = depth_offset;

        while( stackArrayOffset <= error.stackArray.length - 1 ) {

            // Skip our own functions from the trace.
            if( !_token.has_function( f ) ) {
                var trace_data = {};

                if( f ) {
                    trace_data.source    = f;
                    trace_data.arguments = _token.sanitize_arguments( f.arguments );
//                    trace_data.arguments = [
//                        f.arguments[0],
//                        Object.prototype.toString.call( f.arguments[1] ),
//                        Object.prototype.toString.call( f.arguments[2] ),
//                        Object.prototype.toString.call( f.arguments[3] )
//                    ];
//
//                    if( f.arguments[2] instanceof Array ) {
//                        _token.debugging_data.push( f.arguments[2] );
//                    }
                }

                var stack = error.stackArray[stackArrayOffset];
                if( stack.line ) trace_data.line = stack.line - 2;
                if( stack.sourceURL ) trace_data.url  = stack.sourceURL;
                if( stack.function ) trace_data.function = stack.function;

                trace.push( trace_data );
            }

            if( f ) f = f.caller;
            stackArrayOffset++;
        }

        return trace;
    },

    sanitize_arguments: function( arguments ) {
        var clean_args = [];

        for( var i = 0; i < arguments.length; i++ ) {
            var toString = Object.prototype.toString.call( arguments[i] );

            switch( toString ) {
                case '[object HTMLDocument]':
                    clean_args.push( toString );
                    break;

                case '[object DOMWindow]':
                    clean_args.push( toString );
                    break;

                default:
                    clean_args.push( arguments[i] );
            }

        }

        return clean_args;
    },

    has_function: function( func ) {
        // Traced functions are dynamic and can't be compared using === so let's
        // do a quick and dirty check to get this special case over with.
        if( _token.get_traced_function().toString() == (func || '').toString() ) {
            return true;
        }

        // Go over all our functions and see if 'func' matches any of them.
        for( var name in this ) {
            if( this.hasOwnProperty( name ) &&
                Object.prototype.toString.call( this[name] ) === '[object Function]' &&
                func === this[name] ) {
                return true;
            }
        }

        return false;
    },

    get_error_object: function(){
        try { throw Error('') } catch(err) { return err; }
    },

    // Install the overrides.
    override: function () {
        if( _token.overridden ) return;

        _token.override_setTimeout();
        _token.override_setInterval();
        _token.override_addEventListener();
        _token.add_trace_to_prototypes();

        _token.overridden = true
    },

    /**
     * Gets a function that when called will log information about itself if logging is turned on.
     *
     * @param func The function to add logging to.
     *
     * @return A function that will perform logging and then call the function.
     */
    get_traced_function: function( func ) {
        return function() {
            _token.find_and_log_taint( func, arguments );
            return func.apply( this, arguments );
        }
    },

    find_and_log_taint: function ( func, arguments ) {
        var tainted;
        if( _token.taint && (tainted = _token.find_taint_in_arguments( arguments )) ) {
            _token.log_sink({
                source:     func,
                function:   func.name || _token.anonymous_function_names[func],
                arguments:  arguments,
                tainted:    tainted,
                taint:      _token.taint
            });
        }
    },

    find_taint_in_arguments: function( arguments ) {
        for( var i = 0; i < arguments.length; i++ ) {
            var tainted = _token.find_taint_recursively( arguments[i] );
            if ( tainted ) return tainted;
        }

        return null;
    },

    find_taint_recursively: function( object ) {
        var tainted;

        switch( Object.prototype.toString.call( object ) ) {
            case '[object String]':
                if( object.indexOf( _token.taint ) != -1 ) return object;
                break;

            case '[object Array]':
                for( var i = 0; i < object.length; i++ ) {
                    tainted = _token.find_taint_recursively( object[i] );
                    if ( tainted ) return tainted;
                }
                break;

            case '[object Object]':
                for( var property in object ){
                    if( object.hasOwnProperty( property ) ) {
                        var property_value = object[property];

                        if( Object.prototype.toString.call( property_value ) !== '[object Function]' ){
                            tainted = _token.find_taint_recursively( property_value );
                            if ( tainted ) return tainted;
                        }
                    }
                }
                break;
        }

        return null;
    },

    /**
     * After this is called, all direct children of the provided namespace object that are
     * functions will log their name as well as the values of the parameters passed in.
     *
     * @param namespace The object whose child functions you'd like to add logging to.
     */
    add_trace_to_namespace: function( namespace ){
        for( var name in namespace ){
            if( namespace.hasOwnProperty( name ) ){
                var potentialFunction = namespace[name];

                if( Object.prototype.toString.call(potentialFunction) === '[object Function]' ){
                    var namespace_function_name = namespace.toString() + '-' + potentialFunction.name;

                    if( !_token.traced[namespace_function_name] ) {
                        _token.add_trace_to_function( namespace, name );
                        _token.traced[namespace_function_name] = true;
                    }
                }
            }
        }
    },

    add_trace_to_function: function ( object, name ){
        if( !object[name].name )
            _token.anonymous_function_names[object[name]] = name;

        object[name] = _token.get_traced_function( object[name] );
    },

    add_trace_to_setter: function ( object, name ){
        var hashDescriptor = Object.getOwnPropertyDescriptor( object, name ),
            hashSetter = hashDescriptor.set;

        hashDescriptor.set = function (hash) {
            _token.debug( hashDescriptor );
            hashSetter.call(this, hash);
        };
    },

    add_trace_to_prototypes: function () {
        _token.add_trace_to_namespace( CharacterData.prototype );
        _token.add_trace_to_function( Text.prototype, 'replaceWholeText' );

        _token.add_trace_to_function( Document.prototype, 'createTextNode' );
        _token.add_trace_to_function( HTMLDocument.prototype, 'write' );
        _token.add_trace_to_function( HTMLDocument.prototype, 'writeln' );

        _token.add_trace_to_function( Element.prototype, 'setAttribute' );
        _token.add_trace_to_function( HTMLElement.prototype, 'insertAdjacentHTML' );

        _token.add_trace_to_function( String.prototype, 'replace' );
        _token.add_trace_to_function( String.prototype, 'concat' );
    },

    update_tracers: function () {
        _token.add_trace_to_namespace( window );

        if( window.jQuery ) {
            _token.add_trace_to_function( jQuery.fn, 'html' );
            _token.add_trace_to_function( jQuery.fn, 'text' );
            _token.add_trace_to_function( jQuery.fn, 'append' );
            _token.add_trace_to_function( jQuery.fn, 'prepend' );
            _token.add_trace_to_function( jQuery.fn, 'before' );
            _token.add_trace_to_function( jQuery.fn, 'prop' );
            _token.add_trace_to_function( jQuery.fn, 'replaceWith' );
            _token.add_trace_to_function( jQuery.fn, 'val' );
        }
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
