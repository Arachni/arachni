var $warned = false;
function renderResponse( id, html ){

    if ( !$warned ) {
        confirm_render = confirm( "Rendering the response will also execute" +
            " any JavaScript code that might be included in the page. " +
            "Are you sure you want to continue?" );

        $warned = confirm_render;
        if( !confirm_render){
            return;
        }

    }

    $( '#' + id ).html( $( '<iframe style="width: 100%; height: 400px" ' + 'src="' + html + '" />' ) );
}

function toggleElem(id) {
    elem = $( '#' + id);

    if( elem.is(':hidden') ) {
        elem.show();
        sign = '[-]';
    } else {
        elem.hide();
        sign = '[+]';
    }

    elem_sign = $('#' + id + '_sign');
    if( elem_sign ) {
        elem_sign.text( sign );
    }
}


function inspect(id) {
    $(id).dialog({
        height: 500,
        width: 1000,
        modal: true
    });
}

function goTo( location ){
    // Restore the last open tab from the URL fragment.
    if( !location || location.length <= 0 ) return;

    // Clear the current active status of the navigation links.
    $("nav li").removeClass("active");

    var splits          = location.split('/');
    var href_breadcrumb = '#!/';
    var id_breadcrumb   = '';

    for( var i = 0; i < splits.length; i++ ) {
        href_breadcrumb += splits[i];
        id_breadcrumb   += splits[i];

        var tab_selector = $('a[href="' + href_breadcrumb + '"]');
        var level        = $('#' + id_breadcrumb );

        // Mark all links in the navigation tree as active at every step.
        tab_selector.parents('li').siblings().removeClass('active');
        tab_selector.parents('li').addClass('active');

        // Mark all other tabs of this level as inactive...
        level.siblings().removeClass('active');
        //.. and activate the one we want.
        level.addClass('active');

        // In case it's hidden.
        level.show();

        // In case it's a collapsible.
        if( level.hasClass('collapse') ) {
            level.addClass('in');
        }


        if( i != splits.length - 1) {
            href_breadcrumb += '/';
            id_breadcrumb   += '-';
        }
    }

    var target = $('#' + id_breadcrumb);
    if( !target.hasClass('tab-pane') ) {
        $('html,body').scrollTop( target.offset().top );
    }

    if( location == 'summary/charts' ) renderCharts();
}

function goToLocation( location ){
    window.location.hash = '#!/' + location;
}

function openFromWindowLocation(){
    goTo( window.location.hash.split('#!/')[1] );
}

function idFromWindowLocation() {
    return window.location.hash.split('#!/')[1].replace( /\//g, '-' )
}

function scrollToActiveElementFromWindowLocation() {
    $('html,body').scrollTop( $('#' + idFromWindowLocation()).offset().top );
}
