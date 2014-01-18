/*
 * Allows the system to optimize DOM/JS/AJAX analysis by overriding JS prototypes
 * and tracking things like bound events and timers.
 */

var _token = _token || {

    // Signals that our custom monitoring overrides have already been installed
    // for this document.
    initialized: false,

    // If a taint is set the data-flow tracers will inspect their possible
    // sink's arguments and log them if they find the taint.
    taint: null,

    // Allows the 'debug' function to operate.
    enable_debugging: true,

    // Hold debugging information, usually pushed by the 'debug' function.
    debugging_data: [],

    // Execution (log_sink()) and data flow (find_and_log_taint()) sinks.
    sink: [],

    // Holds registered events and their handlers, as added via addEventListener,
    // for each element.
    eventsPerElement: {},

    // Keeps track of setTimeout() calls.
    setTimeouts: [],

    // Keeps track of setInterval() calls.
    setIntervals: [],

    // Keeps track of which functions have had tracers installed.
    traced: {},

    // Namespaces and functions whose data-flow should be monitored.
    data_flow_sinks_to_monitor: {
        // Install tracers for these only during initialization.
        once: [
            CharacterData.prototype,
            [Text.prototype, ['replaceWholeText']],
            [Document.prototype, ['createTextNode']],
            [HTMLDocument.prototype, ['write', 'writeln']],
            [Element.prototype, ['setAttribute']],
            [HTMLElement.prototype, ['insertAdjacentHTML']],
            [String.prototype, ['replace', 'concat']],
            [XMLHttpRequest.prototype, ['open', 'send', 'setRequestHeader']]
        ],

        // Install tracers for these every time a new script is defined in the
        // page.
        watch: [
            // Track the whole window namespace and thus global functions as well.
            window,

            // Track jQuery element functions.
            function () {
                if( !window.jQuery ) return;

                return [
                    // Object to patch.
                    jQuery.fn,

                    // Functions to patch.
                    [
                        'load', 'html', 'text', 'append', 'prepend', 'before',
                        'prop', 'replaceWith', 'val'
                    ],

                    // Friendly name to use to refer to the object -- useful
                    // for logging.
                    'jQuery'
                ]
            },

            // Track jQuery functions.
            function () {
                if( !window.jQuery ) return;

                return [
                    // Object to patch.
                    jQuery,

                    // Functions to patch.
                    [
                        'ajax', 'get', 'post'
                    ],

                    'jQuery'
                ]
            },

            // Track JQLite functions -- provided by AngularJS and emulates
            // JQuery element functions.
            function () {
                if( !window.angular ) return;

                return [
                    // AngularJS keeps its prototypes private so we've got to
                    // be creative if we want direct access so that we can patch
                    // it.
                    Object.getPrototypeOf( angular.element( document ) ),

                    // Basically the same a the jQuery one above, but without
                    // 'before'.
                    [
                        'html', 'text', 'append', 'prepend', 'prop', 'replaceWith',
                        'val'
                    ],

                    // Since that's the only way to access an JQLite instance
                    // I guess this is the best alias to use.
                    'angular.element'
                ]
            },

            // Track *the* JQLite function.
            function () {
                if( !window.angular ) return;
                return [ angular, ['element'], 'angular' ]
            },

            // Trace AngularJS HTTP service functions.
            function () {
                if( !window.angular ) return;

                // We can't grab the $http interface straight up, we need to
                // wait for AngularJS to initialize...
                angular.element(document).ready(function() {

                    // ...and then find an element within the app scope...
                    var element_within_scope = document.querySelectorAll('[ng-app]')[0];
                    if( !element_within_scope ) return;

                    _token.install_tracers_from_list_entry([
                        // ...so that we can use its injector to get $http.
                        angular.element(element_within_scope).injector().get('$http'),
                        [ 'get', 'post', 'head', 'delete', 'put', 'jsonp' ],
                        'angular.$http'
                    ]);
                });
            }

        ]
    },

    // Initialize.
    initialize: function () {
        if( _token.initialized ) return;

        _token.override_setTimeout();
        _token.override_setInterval();
        _token.override_addEventListener();
        _token.initialize_tracers();

        _token.initialized = true
    },

    initialize_tracers: function () {
        _token.install_tracers_from_list( _token.data_flow_sinks_to_monitor.once )
    },

    update_tracers: function () {
        _token.install_tracers_from_list( _token.data_flow_sinks_to_monitor.watch );
    },

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

                    // Scripts with 'use strict' don't let us access arguments.
                    try {
                        trace_data.arguments = _token.sanitize_arguments( f.arguments );
                    } catch(e){}
                }

                var stack = error.stackArray[stackArrayOffset];
                if( stack.line ) trace_data.line = stack.line - 1;
                if( stack.sourceURL ) trace_data.url  = stack.sourceURL;
                if( stack.function ) trace_data.function = stack.function;

                trace.push( trace_data );
            }

            // Scripts with 'use strict' don't let us access function callers.
            if( f ) try { f = f.caller } catch(e){ f = null }
            stackArrayOffset++;
        }

        return trace;
    },

    sanitize_arguments: function( arguments ) {
        var clean_args = [];

        for( var i = 0; i < arguments.length; i++ ) {

            // Event objects need some cleaning up because they hold references
            // to several elements. If any of these elements are no longer there
            // when Watir retrieves the data it'll throw an exception.
            if( arguments[i].eventPhase ) {
                clean_args.push( _token.cleanup_event( arguments[i] ) );
                continue;
            }

            var toString = Object.prototype.toString.call( arguments[i] );

            switch( toString ) {
                case '[object HTMLDocument]':
                case '[object DOMWindow]':
                    clean_args.push( toString );
                    break;

                default:
                    clean_args.push( arguments[i] );
            }

        }

        return clean_args;
    },

    cleanup_event: function( e ) {
        var elements = [
            'toElement', 'target', 'srcElement', 'currentTarget',
            'fromElement'
        ];

        var arg = {};
        for( var prop in e ) {
            if( elements.indexOf( prop ) != -1 && e[prop] ) {

                // Quick and easy, get the element as HTML.
                if( e[prop].outerHTML ) {
                    arg[prop] = e[prop].outerHTML;

                    // Dealing with a HTMLDocument,, needs some special
                    // treatment to get the HTML.
                } else if( e[prop].documentElement ) {
                    arg[prop] = e[prop].documentElement.outerHTML;

                    // You never know...
                } else {
                    arg[prop] = e[prop].toString();
                }
            } else {
                arg[prop] = e[prop];
            }
        }

        return arg;
    },

    has_function: function( func ) {
        // Traced functions are dynamic and can't be compared using === so we
        // have to do a special check for this case.
        if( _token.get_traced_function().toString() == (func || '').toString() ) {
            return true;
        }

        // Go over all our functions and see if 'func' matches any of them.
        for( var name in this ) {
            if( _token.hasOwnProperty( name ) &&
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

    find_and_log_taint: function ( func, arguments, object_name, function_name ) {
        var tainted;

        if( !_token.taint || !(tainted = _token.find_taint_in_arguments( arguments )) )
            return;

        _token.log_sink({
            source:     func,
            function:   func.name || function_name,
            object:     object_name,
            arguments:  arguments,
            tainted:    tainted,
            taint:      _token.taint
        });
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
            if( !namespace.hasOwnProperty( name ) ) continue;

            var potentialFunction = namespace[name];

            if( Object.prototype.toString.call(potentialFunction) !== '[object Function]' )
                continue;

            var namespace_function_name = Object.prototype.toString.call(namespace) +
                '-' + potentialFunction.name;
            if( _token.traced[namespace_function_name] ) continue;

            _token.add_trace_to_function( namespace, name, _token.object_to_name(namespace) );
            _token.traced[namespace_function_name] = true;
        }
    },

    object_to_name: function( object ) {
        return Object.prototype.toString.call( object ).match( /\[[a-zA-Z]+ ([a-zA-Z]+)\]/ )[1]
    },

    /**
     * Gets a function that when called will log information about itself if logging is turned on.
     *
     * @param func The function to add logging to.
     * @param object_name Name of the object that contains 'func'.
     * @param function_name Name of 'func'.
     *
     * @return A function that will perform logging and then call the function.
     */
    get_traced_function: function( func, object_name, function_name ) {
        return function() {
            _token.find_and_log_taint( func, arguments, object_name, function_name );
            return func.apply( this, arguments );
        }
    },

    add_trace_to_function: function ( object, name, object_name  ){
        // Don't trace a tracer.
        if( _token.get_traced_function().toString() == (object[name] || '').toString() )
            return;

        object[name] = _token.get_traced_function(
            object[name], object_name || _token.object_to_name( object ), name
        );
    },

    install_tracers_from_list: function( list ) {
        for( var i = 0; i < list.length; i++ ) {
            if( Object.prototype.toString.call( list[i] ) == '[object Function]' ) {
                _token.install_tracers_from_list_entry( list[i].call() )
            } else {
                _token.install_tracers_from_list_entry( list[i] );
            }
        }
    },

    install_tracers_from_list_entry: function( entry ) {
        if( !entry ) return;

        if( Array.isArray( entry ) ) {
            var namespace = entry[0];

            for( var i = 0; i < entry[1].length; i++ ) {
                _token.add_trace_to_function( namespace, entry[1][i], entry[2] );
            }
        } else {
            _token.add_trace_to_namespace( entry );
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

function debug() {
    _token.debug( arguments );
}
