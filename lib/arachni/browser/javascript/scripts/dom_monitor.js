/*
 * Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>
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

    // Don't include these elements in the `digest` computation.
    exclude_tags_from_digest:        ['P'],

    // Don't include these attributes in the `digest` computation.
    exclude_attributes_from_digest:  ['data-arachni-id'],

    // These elements are interesting enough to be considered by
    // `elements_with_events` even if they don't have any events.
    allowed_elements_without_events: {
        "a": true,
        "input": true,
        "textarea": true,
        "select": true,
        "form": true
    },

    // These elements are allowed to inherit events from their ancestors.
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

    // These elements should not have events so ignore them.
    elements_without_events: {
        "base" : true,
        "bdo" : true,
        "br" : true,
        "head" : true,
        "html" : true,
        "iframe" : true,
        "meta" : true,
        "param" : true,
        "script" : true,
        "style" : true,
        "title" : true,
        "link" : true,
        "hr" : true
    },

    // These events are valid for all elements.
    universally_valid_events: {
        "click" : true,
        "dblclick" : true,
        "mousedown" : true,
        "mousemove" : true,
        "mouseout" : true,
        "mouseover" : true,
        "mouseup" : true
    },

    // Valid events for interesting elements, any other events will be ignored.
    valid_events_per_element:{
        "body" : {
            "load": true
        },
        "form" : {
            "submit": true,
            "reset": true
        },
        "input" : {
            "select": true,
            "change": true,
            "focus": true,
            "blur": true,
            "keydown": true,
            "keypress": true,
            "keyup": true,
            "input": true
        },
        "textarea" : {
            "select": true,
            "change": true,
            "focus": true,
            "blur": true,
            "keydown": true,
            "keypress": true,
            "keyup": true,
            "input": true
        },
        "select" : {
            "change": true,
            "focus": true,
            "blur": true
        },
        "button" : {
            "focus": true,
            "blur": true
        },
        "label" : {
            "focus": true,
            "blur": true
        }
    },

    // Generally valid events for when there's no element tag name, like for
    // Window and Document.
    valid_events: {
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

    initialize: function () {
        if( _tokenDOMMonitor.initialized ) return;

        _tokenDOMMonitor.track_setTimeout();
        _tokenDOMMonitor.track_addEventListener();

        _tokenDOMMonitor.initialized = true
    },

    update_trackers: function () {
    },

    // Returns information about all DOM elements that have events, along with
    // some that are interesting enough to be included even without them.
    //
    // @param   {Number}    offset
    //  Start processing elements at the given offset.
    // @param   {Number}    batch_size
    //  Max amount of elements to be returned.
    //  Helps keep Selenium response sizes low to keep RAM usage under control
    //  for pages with a large number of elements with events.
    elements_with_events: function ( offset, batch_size, tag_name_whitelist ) {
        tag_name_whitelist = tag_name_whitelist || [];

        var whitelist = {};
        for( var f = 0; f < tag_name_whitelist.length; f++ ) {
            whitelist[tag_name_whitelist[f]] = true;
        }

        var events_with_elements = [];
        var elements = document.getElementsByTagName("*");
        var length   = elements.length;

        var global_events = window._arachni_events || [];
        global_events = global_events.concat( document._arachni_events || [] );
        global_events = _tokenDOMMonitor.arrayUnique( global_events );

        // Keeps track of the amount of relevant elements (i.e. with events), to
        // help with the creation of the batch that should be returned based on
        // `offset` and `batch_size`.
        var relevant_element_index = 0;

        for( var i = 0; i < length; i++ ) {
            var element = elements[i];

            var tag_name = element.tagName.toLowerCase();

            if( _tokenDOMMonitor.is_element_without_events( tag_name ) )
                continue;

            // Pass this element's events down to its descendants.
            _tokenDOMMonitor.bequeath_events( element );

            if( tag_name_whitelist.length > 0 && !whitelist[tag_name] ) continue;

            // Skip invisible elements.
            if( element.offsetWidth <= 0 && element.offsetHeight <= 0 ) continue;

            var e = {
                tag_name:   tag_name,
                events:     element._arachni_events || [],
                attributes: {}
            };

            // If the current element is allowed to have inherited events
            // merge them with its own.
            if( _tokenDOMMonitor.is_allowed_element_with_inherited_events( e.tag_name ) ) {
                e.events = e.events.concat( element._arachni_inherited_events || [] );
                e.events = _tokenDOMMonitor.arrayUnique( e.events.concat( global_events ) );
            }

            var attributes  = element.attributes;
            var attr_length = attributes.length;

            // Extract attributes and events from them.
            for( var j = 0; j < attr_length; j++ ){
                var attr_name = attributes[j].nodeName;

                // Extract events and handlers from attributes and set them as
                // element events -- but only if they are appropriate for the
                // element type.
                if( _tokenDOMMonitor.is_valid_event_for_element( tag_name, attr_name ) ) {
                    e.events.push(
                        [
                            attr_name.replace( 'on', '' ),
                            attributes[j].nodeValue
                        ]
                    )
                }

                e.attributes[attr_name] = attributes[j].nodeValue;
            }

            // No events and the element isn't interesting enough to be taken
            // into account without any, skip it.
            if( !_tokenDOMMonitor.is_allowed_element_without_event( e.tag_name ) &&
                e.events.length == 0 ) {
                continue
            }

            // Group events and their handlers by event type, instead of having
            // them as independent tuples; and while we're at it do some
            // normalization too.
            var grouped_events = {};
            for( var k = 0; k < e.events.length; k++ ) {
                var event         = e.events[k];
                var event_name    = event[0].replace( 'on', '' );
                var event_handler = event[1];

                // Event type not appropriate for element, we don't know why and
                // we don't care, we shouldn't waste resources on it.
                if( !_tokenDOMMonitor.is_valid_event_for_element( tag_name, event_name ) ) {
                    continue;
                }

                grouped_events[event_name] = grouped_events[event_name] || [];
                grouped_events[event_name].push( event_handler );
            }
            e.events = grouped_events;

            // Increase the index for the batch of elements that can be returned.
            relevant_element_index += 1;

            // If the batch index reached the specified offset allow for the
            // batch to be created, otherwise ignore the element.
            if( offset && relevant_element_index <= offset ) continue;

            events_with_elements.push( e );

            // Batch size reached, send it on its way.
            if( batch_size && events_with_elements.length == batch_size )
                return events_with_elements;
        }

        // If we got here it means that the current batch didn't reach max size,
        // just send whatever we managed to collect.
        return events_with_elements;
    },

    // Digest used to determine whether or not a page has already been seen,
    // based on the currently available events.
    //
    // Uses both elements and their DOM events and possible audit workload to
    // determine the ID, as page snapshots should be retained both when further
    // browser analysis can be performed and when new element audit workload
    // (but possibly without any DOM relevance) is available.
    event_digest: function () {
        var id       = '';
        var elements = _tokenDOMMonitor.elements_with_events();

        for( var i = 0; i < elements.length; i++ ) {
            var element    = elements[i];
            var element_id = '';

            switch( element.tag_name ) {
                case 'a':
                    element_id += element.attributes.href;
                    break;

                case 'input':
                case 'textarea':
                case 'select':
                    element_id += element.attributes.name;
                    break;

                case 'form':
                    element_id += element.attributes.name;
                    element_id += ',';
                    element_id += element.attributes.action;
                    break;
            }

            id += element.tag_name + ':' + element_id + ':' +
                Object.keys(element.events).join();
            id += '-';
        }

        id += 'cookies:' + _tokenDOMMonitor.cookie_names_csv();

        return _tokenDOMMonitor.hashCode( id ).toString();
    },

    cookie_names_csv: function () {
        var cookies = document.cookie.split(';');
        var csv = '';

        for( var i = 0; i < cookies.length; i++ ) {
            csv += cookies[i].split( '=' )[0];
        }

        return csv;
    },

    // Returns an Integer digest of the current DOM tree (i.e. node names and
    // their attributes without text-nodes).
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

        return _tokenDOMMonitor.hashCode( digest );
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

    // Passes down the element's events to its descendants.
    bequeath_events: function( element ) {
        var children = element.childNodes;

        for( var i = 0; i < children.length; i++ ) {
            var child = children[i];

            if( !('_arachni_inherited_events' in child) ) child['_arachni_inherited_events'] = [];

            // Merge the element's events with the child's existing inherited ones.
            if( element['_arachni_events'] ) {
                child['_arachni_inherited_events'] =
                    element['_arachni_events'].concat( child['_arachni_inherited_events'] );
            }

            // Merge the element's inherited events with the child's existing
            // inherited ones.
            if( element['_arachni_inherited_events'] ) {
                child['_arachni_inherited_events'] =
                    element['_arachni_inherited_events'].concat( child['_arachni_inherited_events'] );
            }

            // Make sure we didn't add duplicates.
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

        // There's no tag name (so we're dealing with Window or Document) and
        // the event doesn't generally look valid, bail out.
        if( !element.tagName && !_tokenDOMMonitor.is_valid_event( event ) )
            return;

        // There's a tag name but the event isn't valid for the element type,
        // bail out.
        if(
            element.tagName && !_tokenDOMMonitor.is_valid_event_for_element(
            element.tagName.toLowerCase(), event
        )
            ) {
            return;
        }

        // All is well, register the event with the element.
        element['_arachni_events'].push( [event, handler] );
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

    is_valid_event: function ( event ) {
        return Object.prototype.hasOwnProperty.call(
            _tokenDOMMonitor.valid_events,
            event.replace( 'on', '' )
        );
    },

    is_valid_event_for_element: function ( tag, event ) {
        event = event.replace( 'on', '' );

        if( Object.prototype.hasOwnProperty.call(
            _tokenDOMMonitor.universally_valid_events,
            event )){ return true; }

        return _tokenDOMMonitor.valid_events_per_element[tag] &&
            Object.prototype.hasOwnProperty.call(
                _tokenDOMMonitor.valid_events_per_element[tag],
                event
            )
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

    is_element_without_events: function ( tag_name ) {
        return Object.prototype.hasOwnProperty.call(
            _tokenDOMMonitor.elements_without_events,
            tag_name
        );
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
