/*
 * Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>
 *
 * This file is part of the Arachni Framework project and is subject to
 * redistribution and commercial restrictions. Please see the Arachni Framework
 * web site for more information on licensing and terms of use.
 */

/*
 * Tracks the configured 'taint' throughout the Javascript environment's data
 * and execution flow.
 */
var _tokenTaintTracer = _tokenTaintTracer || {

    // Signals that our custom monitoring overrides have already been installed
    // for this document.
    initialized:          false,

    // If taints are set, the data-flow tracers will inspect their possible
    // sink's arguments and log them if they find the taint.
    taints:               {},

    // Allows the 'debug' function to operate.
    enable_debugging:     true,

    max_sinks:            50,

    // Limits the maximum depth when traversing object properties, looking for
    // taints -- safeguard for circular references.
    find_taint_recursively_max_depth: 3,

    // Hold debugging information, usually pushed by the 'debug' function.
    debugging_data:       [],

    // Execution-flow (log_execution_flow_sink()) sink.
    execution_flow_sinks: [],

    // Data-flow (find_and_log_taint() -- log_data_flow_sink()) sinks, with
    // taints as keys and traces as values.
    data_flow_sinks:      {},

    ignore:               {
        '':        true,
        'lodash':  true
    },

    // Keeps track of which functions have had tracers installed.
    traced:               {},

    // Original functions, without tracers. We don't want to trigger traced
    // functions to provide functionality to this object.
    originals:            {
        'String.indexOf': String.prototype['indexOf']
    },

    // Namespaces and functions whose data-flow should be monitored.
    data_flow_sinks_to_monitor: {
        // Install tracers for these only during initialization.
        once: [
            CharacterData.prototype,
            [
                window,
                [
                    // Eval is magic as it can read/write the caller's local
                    // variables, something that would not work if we were to
                    // proxy it in order to trace it.
                    //
                    // 'eval',
                    'encodeURIComponent', 'decodeURIComponent', 'encodeURI',
                    'decodeURI', 'escape', 'unescape'
                ]
            ],
            [Text.prototype, ['replaceWholeText']],
            [Document.prototype, ['createTextNode']],
            [HTMLDocument.prototype, ['write', 'writeln']],
            [Element.prototype, ['setAttribute']],
            [HTMLElement.prototype, ['insertAdjacentHTML']],
            [String.prototype, ['replace', 'concat', 'indexOf', 'lastIndexOf']],
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
                        'ajax', 'get', 'post', 'cookie'
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

                    // Since that's the only way to access a JQLite instance
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

                    _tokenTaintTracer.install_tracers_from_list_entry([
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
    initialize: function ( taints ) {
        if( _tokenTaintTracer.initialized ) return;

        _tokenTaintTracer.taints = taints;

        if( !_tokenTaintTracer.isEmpty( taints ) ) {
            _tokenTaintTracer.install_tracers_from_list( _tokenTaintTracer.data_flow_sinks_to_monitor.once );
        }

        _tokenTaintTracer.initialized = true
    },

    update_tracers: function () {
        _tokenTaintTracer.install_tracers_from_list( _tokenTaintTracer.data_flow_sinks_to_monitor.watch );
    },

    debug: function (){
        if( !_tokenTaintTracer.enable_debugging ) return;

        _tokenTaintTracer.debugging_data.push({
            data:  arguments,
            trace: _tokenTaintTracer.trace()
        })
    },

    has_sinks: function ( taint ){
        return _tokenTaintTracer.execution_flow_sinks.length > 0 ||
            _tokenTaintTracer.data_flow_sinks[taint]
    },

    log_data_flow_sink: function ( taint, frame_data ){
        _tokenTaintTracer.data_flow_sinks[taint] =
            _tokenTaintTracer.data_flow_sinks[taint] || [];

        _tokenTaintTracer.data_flow_sinks[taint].push({
            data:  frame_data,
            trace: _tokenTaintTracer.taints[taint].trace ?
                    _tokenTaintTracer.trace() : []
        });

        if( _tokenTaintTracer.data_flow_sinks[taint].length > _tokenTaintTracer.max_sinks ) {
            _tokenTaintTracer.data_flow_sinks[taint] =
                _tokenTaintTracer.data_flow_sinks[taint].slice(
                        _tokenTaintTracer.data_flow_sinks[taint].length -
                        _tokenTaintTracer.max_sinks,
                    _tokenTaintTracer.data_flow_sinks[taint].length
                )
        }
    },

    log_execution_flow_sink: function (){
        _tokenTaintTracer.execution_flow_sinks.push({
            data:  arguments,
            trace: _tokenTaintTracer.trace()
        });

        if( _tokenTaintTracer.execution_flow_sinks.length > _tokenTaintTracer.max_sinks ) {
            _tokenTaintTracer.execution_flow_sinks =
                _tokenTaintTracer.execution_flow_sinks.slice(
                        _tokenTaintTracer.execution_flow_sinks.length -
                        _tokenTaintTracer.max_sinks,
                    _tokenTaintTracer.execution_flow_sinks.length
                )
        }
    },

    flush_execution_flow_sinks: function (){
        var a = _tokenTaintTracer.execution_flow_sinks;
        _tokenTaintTracer.execution_flow_sinks = [];
        return a;
    },

    flush_data_flow_sinks: function (){
        var a = _tokenTaintTracer.data_flow_sinks;
        _tokenTaintTracer.data_flow_sinks = {};
        return a;
    },

    trace: function ( depth_offset ) {
        var f = arguments.callee,
            trace = [];

        depth_offset = parseInt( depth_offset ) || 3;
        for( var i = 0; i < depth_offset - 1; i++ ) {
            if( f ) f = f.caller;
        }

        var error = _tokenTaintTracer.get_error_object();
        var stackArrayOffset = depth_offset;

        var stack_messages = error.stack.split( '\n' );
        while( stackArrayOffset <= stack_messages.length - 1 ) {
            // Skip our own functions from the trace.
            if( !_tokenTaintTracer.has_function( f ) ) {
                var frame = {
                    function: {}
                };

                if( f ) {
                    frame.function.source = f;

                    // Scripts with 'use strict' don't let us access arguments.
                    try {
                        frame.function.arguments =
                            _tokenTaintTracer.sanitize_arguments( f.arguments );
                    } catch(e){}
                }

                var stack = stack_messages[stackArrayOffset];

                var name_rest_splits;
                if( stack.indexOf( '@' ) !== -1 ) {
                    name_rest_splits = stack.split( '@', 2 );
                    frame.function.name = name_rest_splits.shift();
                } else {
                    name_rest_splits = [stack];
                }

                if( name_rest_splits.length > 0 ) {
                    stack = name_rest_splits.shift();
                    var url_line_splits = stack.split( ':' );

                    // Remove the column.
                    url_line_splits.pop();

                    frame.line = parseInt( url_line_splits.pop() );
                    frame.url = url_line_splits.join( ':' );
                }

                trace.push( frame );
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
                clean_args.push( _tokenTaintTracer.cleanup_event( arguments[i] ) );
                continue;
            }

            var toString = Object.prototype.toString.call( arguments[i] );

            // Keep it simple and whitelist to avoid cases where Selenium can't
            // handle custom objects. When in doubt, just return the type.
            switch( toString ) {
                case '[object String]':
                case '[object Function]':
                case '[object Number]':
                case '[object Boolean]':
                    clean_args.push( arguments[i] );
                    break;

                // Maybe do some magic to traverse the object?
                case '[object Object]':
                default:
                    clean_args.push( toString );
                    break;
            }

        }

        return clean_args;
    },

    cleanup_event: function( e ) {
        var keep = [
            'toElement',
            'target',
            'srcElement',
            'currentTarget',
            'fromElement',
            'eventPhase',
            'type'
        ];

        var prop;
        var event_data = {};
        for( var i = 0; i < keep.length; i++ ) {
            prop = keep[i];

            if( !e[prop] ) continue;

            // Quick and easy, get the element as HTML.
            if( e[prop].outerHTML ) {
                event_data[prop] = e[prop].outerHTML;

                // Dealing with a HTMLDocument, needs some special treatment to get the HTML.
            } else if( e[prop].documentElement ) {
                event_data[prop] = e[prop].documentElement.outerHTML;

                // You never know...
            } else {
                event_data[prop] = e[prop].toString();
            }
        }

        return event_data;
    },

    has_function: function( func ) {
        // Traced functions are dynamic and can't be compared using === so we
        // have to do a special check for this case.
        if( _tokenTaintTracer.get_traced_function().toString() == (func || '').toString() ) {
            return true;
        }

        // Go over all our functions and see if 'func' matches any of them.
        for( var name in this ) {
            if( _tokenTaintTracer.hasOwnProperty( name ) &&
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

        for( var taint in _tokenTaintTracer.taints ) {
            if(
                !_tokenTaintTracer.taints.hasOwnProperty( taint ) ||
                (
                    _tokenTaintTracer.taints[taint].stop_at_first &&
                    _tokenTaintTracer.data_flow_sinks[taint]
                )
            ) continue;

            tainted = _tokenTaintTracer.find_taint_in_arguments( taint, arguments );
            if( !tainted ) continue;

            _tokenTaintTracer.log_data_flow_sink( taint, {
                function:               {
                    source:    func,
                    name:      func.name || function_name,
                    arguments: arguments
                },
                object:                 object_name,
                tainted_argument_index: tainted[0],
                tainted_value:          tainted[1],
                taint:                  taint
            });
        }
    },

    find_taint_in_arguments: function( taint, arguments ) {
        for( var i = 0; i < arguments.length; i++ ) {
            var tainted = _tokenTaintTracer.find_taint_recursively( taint, arguments[i] );
            if( tainted ) return [i, tainted];
        }

        return null;
    },

    find_taint_recursively: function( taint, object, depth ) {
        var tainted;
        depth = depth || 0;

        if( depth > _tokenTaintTracer.find_taint_recursively_max_depth ) return;
        depth++;

        switch( Object.prototype.toString.call( object ) ) {
            case '[object String]':
                if( _tokenTaintTracer.originals['String.indexOf'].apply( object, [taint] ) != -1 ) return object;
                break;

            case '[object Array]':
                for( var i = 0; i < object.length; i++ ) {
                    tainted = _tokenTaintTracer.find_taint_recursively(
                        taint,
                        object[i],
                        depth
                    );

                    if ( tainted ) return tainted;
                }
                break;

            case '[object Object]':
                for( var property in object ){
                    if( object.hasOwnProperty( property ) ) {
                        var property_value = object[property];

                        if( Object.prototype.toString.call( property_value ) !== '[object Function]' ){
                            tainted = _tokenTaintTracer.find_taint_recursively(
                                taint,
                                property_value,
                                depth
                            );

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

            if( _tokenTaintTracer.ignore[potentialFunction.name] ) continue;

            var namespace_function_name = Object.prototype.toString.call(namespace) +
                '-' + potentialFunction.name;
            if( _tokenTaintTracer.traced[namespace_function_name] ) continue;

            _tokenTaintTracer.add_trace_to_function( namespace, name, _tokenTaintTracer.object_to_name(namespace) );
            _tokenTaintTracer.traced[namespace_function_name] = true;
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
            _tokenTaintTracer.find_and_log_taint( func, arguments, object_name, function_name );
            return func.apply( this, arguments );
        }
    },

    add_trace_to_function: function ( object, name, object_name  ){
        // object[name].toString() can fail for certain functions so play it
        // safe and bail out.
        try {
            // Don't trace a tracer.
            if( _tokenTaintTracer.get_traced_function().toString() == (object[name] || '').toString() )
                return;
        } catch (e) {
            return;
        }

        var function_needle = 'function ' + name + '(';

        // Not a function but a constructor for a class-like structure, don't
        // break it (we can't handle 'this' context for classes).
        //
        // We only check for user-specified ones, under Window, because these
        // are unknown; framework-specified ones have been vetted.
        if(
            object == window && object[name] &&
            (
                // The name should be the same as the function name...
                object[name].toString().substring( 0, function_needle.length ) !== function_needle ||

                // .. and the prototype needs to not have any members.
                (
                    object[name].prototype &&
                    !_tokenTaintTracer.isEmpty( object[name].prototype )
                )
            )
        ) return;

        object[name] = _tokenTaintTracer.get_traced_function(
            object[name], object_name || _tokenTaintTracer.object_to_name( object ), name
        );

    },

    install_tracers_from_list: function( list ) {
        for( var i = 0; i < list.length; i++ ) {
            if( Object.prototype.toString.call( list[i] ) == '[object Function]' ) {
                _tokenTaintTracer.install_tracers_from_list_entry( list[i].call() )
            } else {
                _tokenTaintTracer.install_tracers_from_list_entry( list[i] );
            }
        }
    },

    install_tracers_from_list_entry: function( entry ) {
        if( !entry ) return;

        if( Array.isArray( entry ) ) {
            var namespace = entry[0];

            for( var i = 0; i < entry[1].length; i++ ) {
                _tokenTaintTracer.add_trace_to_function( namespace, entry[1][i], entry[2] );
            }
        } else {
            _tokenTaintTracer.add_trace_to_namespace( entry );
        }
    },

    isEmpty: function ( obj ) {
        for( var prop in obj ) {
            if( obj.hasOwnProperty( prop ) )
                return false;
        }

        return true;
    }
};

// Aliases to catch cases where the input is being transformed (to lower case etc.).
var _token_taint_tracer = _token_taint_tracer || _tokenTaintTracer;
var _tokentainttracer = _tokentainttracer  || _tokenTaintTracer;
