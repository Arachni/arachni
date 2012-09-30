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
