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

function report_fp(i) {

    if (!email_address) {
        email_address = prompt("Please enter your e-mail address:", "")
    }

    if (!email_address) return false;

    // get some values from elements on the page:
    var $form = $("#false_positive_" + i),
        issue = $form.find('input[name="issue"]').val(),
        module = $form.find('input[name="module"]').val(),
        url = $form.find('input[name="url"]').val();

    // Send the data using post and put the results in a div
    $.post("<%=REPORT_FP_URL%>", {
        email_address: email_address,
        url: url,
        module: module,
        issue: issue,
        configuration: configuration
    }, function () {
        $("#fp_report_msg").html("Done!")
    });

    $(function () {
        var fp_txt = '<p>Please wait while the data is being transferred...</p>';
        $("#fp_report_msg").html(fp_txt);

        $("#fp_report_msg").dialog({
            modal: true,
            buttons: {
                Ok: function () {
                    $(this).dialog("close");
                    $("#fp_report_msg").html(fp_txt);
                }
            }
        });
    });

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
