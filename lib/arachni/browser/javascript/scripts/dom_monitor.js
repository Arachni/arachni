/*
 * Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>
 *
 * This file is part of the Arachni Framework project and is subject to
 * redistribution and commercial restrictions. Please see the Arachni Framework
 * web site for more information on licensing and terms of use.
 */

//if( !window.onerror ) {
//    window.errors = [];
//    window.onerror = function() {
//        window.errors.push( arguments )
//    };
//}

/*
 * Allows the system to optimize DOM/JS/AJAX analysis by overriding JS prototypes
 * and tracking things like bound events and timers.
 */
var _tokenDOMMonitor = _tokenDOMMonitor || {

    // Signals that our custom monitoring overrides have already been installed
    // for this document.
    initialized:         false,

    // Keeps track of setTimeout() calls.
    timeouts:            [],

    // Keeps track of setInterval() calls.
    intervals:           [],

    exclude_tags_from_digest:        ['P'],
    
    exclude_attributes_from_digest:  ['data-arachni-id'],

    event_attributes: {
        "click" : true,
        "dblclick" : true,
        "mousedown" : true,
        "mousemove" : true,
        "mouseout" : true,
        "mouseover" : true,
        "mouseup" : true,
        "load" : true,
        "submit" : true,
        "reset" : true,
        "select" : true,
        "change" : true,
        "focus" : true,
        "blur" : true,
        "keydown" : true,
        "keypress" : true,
        "keyup" : true,
        "input" : true
    },

    allowed_elements_without_events: {
        "a": true,
        "input": true,
        "textarea": true,
        "select": true,
        "form": true
    },

    allowed_elements_with_inherited_events: {
        "a": true,
        "input": true,
        "textarea": true,
        "select": true,
        "form": true,
        "li": true,
        "span": true,
        "button": true
    },

    initialize: function () {
        if( _tokenDOMMonitor.initialized ) return;

        _tokenDOMMonitor.track_setTimeout();
        _tokenDOMMonitor.track_setInterval();
        _tokenDOMMonitor.track_addEventListener();

        _tokenDOMMonitor.initialized = true
    },

    update_trackers: function () {
    },

    // Returns information about all DOM elements that have events, along with
    // some elements that
    elements_with_events: function () {
        var events_with_elements = [];
        var elements = document.getElementsByTagName("*");
        var length   = elements.length;

        var global_events = window._arachni_events || [];
        global_events = global_events.concat( document._arachni_events || [] );
        global_events = _tokenDOMMonitor.arrayUnique( global_events );

        for( var i = 0; i < length; i++ ) {
            var has_events = false;
            var element = elements[i];

            _tokenDOMMonitor.bequeath_events( element );

            // Skip invisible elements.
            if( element.offsetWidth <= 0 && element.offsetHeight <= 0 ) continue;

            var e = {
                tag_name:   element.tagName.toLowerCase(),
                events:     element._arachni_events || [],
                attributes: {}
            };

            if( _tokenDOMMonitor.is_allowed_element_with_inherited_events( e.tag_name ) ) {
                e.events = e.events.concat( element._arachni_inherited_events || [] );
                e.events = _tokenDOMMonitor.arrayUnique( e.events.concat( global_events ) );
            }

            var attributes  = element.attributes;
            var attr_length = attributes.length;

            for( var j = 0; j < attr_length; j++ ){
                var attr_name = attributes[j].nodeName;

                if( _tokenDOMMonitor.is_valid_event( attr_name ) ) {
                    has_events = true;
                }

                e.attributes[attr_name] = attributes[j].nodeValue;
            }

            if( !_tokenDOMMonitor.is_allowed_element_without_event( e.tag_name ) &&
                !has_events && e.events.length == 0 ) {
                continue
            }
            has_events = false;

            events_with_elements.push( e );
        }

        return events_with_elements;
    },

    is_valid_event: function ( event ) {
        return Object.prototype.hasOwnProperty.call(
            _tokenDOMMonitor.event_attributes,
            event.replace( 'on', '' )
        );
    },

    is_allowed_element_without_event: function ( tag_name ) {
        return Object.prototype.hasOwnProperty.call(
            _tokenDOMMonitor.allowed_elements_without_events,
            tag_name
        );
    },

    is_allowed_element_with_inherited_events: function ( tag_name ) {
        return Object.prototype.hasOwnProperty.call(
            _tokenDOMMonitor.allowed_elements_with_inherited_events,
            tag_name
        );
    },

    // Returns a string digest of the current DOM tree (i.e. node names and their
    // attributes without text-nodes).
    digest: function () {
        var elements = document.getElementsByTagName("*");
        var length   = elements.length;

        var digest = '';
        for( var i = 0; i < length; i++ ) {
            var element = elements[i];

            if( _tokenDOMMonitor.exclude_tags_from_digest.indexOf( element.tagName ) > -1 )
                continue;

            digest += '<' + element.tagName;

            var attributes  = element.attributes;
            var attr_length = attributes.length;

            for( var j = 0; j < attr_length; j++ ){
                if( _tokenDOMMonitor.exclude_attributes_from_digest.indexOf( attributes[j].nodeName ) > -1 )
                    continue;

                digest += ' ' + attributes[j].nodeName + '=' + attributes[j].nodeValue;
            }
            digest += '>'
        }

        return digest;
    },

    // Override setInterval() so that we'll know to wait for it to be triggered
    // during DOM analysis to provide sufficient coverage.
    track_setInterval: function () {
        var original_setInterval = window.setInterval;

        window.setInterval = function() {
            _tokenDOMMonitor.intervals.push( arguments );
            original_setInterval.apply( this, arguments );
        };
    },

    // Override setTimeout() so that we'll know to wait for it to be triggered
    // during DOM analysis to provide sufficient coverage.
    track_setTimeout: function () {
        var original_setTimeout = window.setTimeout;

        window.setTimeout = function() {
            arguments[1] = parseInt( arguments[1] );
            _tokenDOMMonitor.timeouts.push( arguments );
            original_setTimeout.apply( this, arguments );
        };
    },

    // Overrides window.addEventListener and Node.prototype.addEventListener
    // to intercept event binds so that we can keep track of them in order to
    // optimize DOM analysis.
    track_addEventListener: function () {
        // Override window.addEventListener
        var original_Window_addEventListener = window.addEventListener;

        window.addEventListener = function ( event, listener, useCapture ) {
            _tokenDOMMonitor.registerEvent( window, event, listener );
            original_Window_addEventListener.apply( window, [].slice.call( arguments ) );
        };

        // Override document.addEventListener
        var original_Document_addEventListener = document.addEventListener;

        document.addEventListener = function ( event, listener, useCapture ) {
            _tokenDOMMonitor.registerEvent( document, event, listener );
            original_Document_addEventListener.apply( document, [].slice.call( arguments ) );
        };

        // Override Node.prototype.addEventListener
        var original_Node_addEventListener = Node.prototype.addEventListener;

        Node.prototype.addEventListener = function ( event, listener, useCapture ) {
            _tokenDOMMonitor.registerEvent( this, event, listener );
            original_Node_addEventListener.apply( this, [].slice.call( arguments ) );
        };
    },

    bequeath_events: function( element ) {
        var children = element.childNodes;

        for( var i = 0; i < children.length; i++ ) {
            var child = children[i];

            if( !('_arachni_inherited_events' in child) ) child['_arachni_inherited_events'] = [];

            if( element['_arachni_events'] ) {
                child['_arachni_inherited_events'] =
                    element['_arachni_events'].concat( child['_arachni_inherited_events'] );
            }

            if( element['_arachni_inherited_events'] ) {
                child['_arachni_inherited_events'] =
                    element['_arachni_inherited_events'].concat( child['_arachni_inherited_events'] );
            }

            child['_arachni_inherited_events'] =
                _tokenDOMMonitor.arrayUnique( child['_arachni_inherited_events'] )
        }
    },

    arrayUnique: function( array ) {
        var a = array.concat();

        for( var i = 0; i < a.length; ++i ) {
            for( var j = i + 1; j < a.length; ++j ) {
                if( a[i] === a[j] )
                    a.splice( j--, 1 );
            }
        }

        return a;
    },

    // Registers an event and its handler for the given element.
    registerEvent: function ( element, event, handler ) {
        if( !('_arachni_events' in element) ) element['_arachni_events'] = [];

        // Custom events are usually in the form of "click.delegateEventsview13".
        event = event.split( '.' )[0];

        if( _tokenDOMMonitor.is_valid_event( event ) ) {
            element['_arachni_events'].push( [event, handler] );
        }
    },

    // Sets a unique enough custom ID attribute to elements that lack proper IDs.
    // This gets called externally (by the Browser) once the page is settled.
    setElementIds: function() {
        var elements = document.getElementsByTagName("*");
        var length   = elements.length;

        for( var i = 0; i < length; i++ ) {
            var element = elements[i];

            // Window and others don't have attributes.
            if( typeof( element.getAttribute ) !== 'function' ||
                typeof( element.setAttribute) !== 'function' ) continue;

            // If the element has an ID we're cool, move on.
            if( element.getAttribute('id') ) continue;

            // Skip invisible elements.
            if( element.offsetWidth <= 0 && element.offsetHeight <= 0 ) continue;

            // We don't care about elements without events.
            if( !element._arachni_events || element._arachni_events.length == 0 ) continue;

            element.setAttribute( 'data-arachni-id', _tokenDOMMonitor.hashCode( element.innerHTML ) );
        }
    },

    hashCode: function( str ) {
        var hash = 0;
        if( str.length == 0 ) return hash;

        for( var i = 0; i < str.length; i++ ) {
            var char = str.charCodeAt( i );
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32bit integer
        }

        return hash;
    }
};

_tokenDOMMonitor.initialize();
