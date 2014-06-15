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

function searchIssues( val ){
    $(".issue").show();

    if( val != '' ){
        $(".issue:not(:icontains(" + val +"))").hide();
    } else {
        $(".issue").show();
    }
}

function goTo( location ){
    // Restore the last open tab from the URL fragment.
    if( !location || location.length <= 0 ) return;

    // Clear the current active status of the navigation links.
    $("nav li").removeClass("active");

    var splits     = location.split('-');
    var breadcrumb = '';

    for( var i = 0; i < splits.length; i++ ) {
        breadcrumb += splits[i];

        var target = $('a[href="#' + breadcrumb + '"]');
        target.tab('show');

        // Mark all links in the navigation tree as active at every step.
        target.parents('li').addClass('active');

        breadcrumb += '-';
    }

    var target = $('#' + location);
    if( !target.hasClass('tab-pane') ) {
        $('html,body').scrollTop( target.offset().top );
    }
}

function openFromWindowLocation(){
    goTo( window.location.hash.split('#')[1] );
}
