/*
 * Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
 *
 * This file is part of the Arachni Framework project and is subject to
 * redistribution and commercial restrictions. Please see the Arachni Framework
 * web site for more information on licensing and terms of use.
 */

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

    // Initialize.
    initialize: function () {
        if( _tokenDOMMonitor.initialized ) return;

        _tokenDOMMonitor.track_setTimeout();
        _tokenDOMMonitor.track_setInterval();
        _tokenDOMMonitor.track_addEventListener();

        _tokenDOMMonitor.initialized = true
    },

    // Returns information about all DOM elements, their attributes and registered
    // events.
    elements_with_events: function () {
        var events_with_elements = [];
        var elements = document.getElementsByTagName("*");
        var length   = elements.length;

        for( var i = 0; i < length; i++ ) {
            var element = elements[i];

            // Skip invisible elements.
            if( element.offsetWidth <= 0 && element.offsetHeight <= 0 ) continue;

            var e = {
                tag_name:   element.tagName.toLowerCase(),
                events:     element.events || [],
                attributes: {}
            };

            var attributes  = element.attributes;
            var attr_length = attributes.length;

            for( var j = 0; j < attr_length; j++ ){
                e.attributes[attributes[j].nodeName] = attributes[j].nodeValue;
            }

            events_with_elements.push( e );
        }

        return events_with_elements;
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
    },

    // Registers an event and its handler for the given element.
    registerEvent: function ( element, event, handler ) {
        if( !('events' in element) ) element['events'] = [];
        element['events'].push( [event, handler] );
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
            if( !element.events || element.events.length == 0 ) continue;

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
