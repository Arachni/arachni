$(window).ready( function( $ ) {

    $(document).ajaxStart( function() {
        $("#loading").show();
    }).ajaxStop( function() {
        $("#loading").hide();
    });

    $('.newWindow').click( function( event ){

        var url = $(this).attr("href");
        var windowName = $(this).attr("name");
        var windowSize = 'width=1024,height=600,scrollbars=yes,menubar=no,toolbar=no';

        window.open( url, windowName, windowSize );

        event.preventDefault();
    });

    $('#close').click( function( event ){
        window.close();
    });

    $('#start-recording').click( function( event ){
        event.preventDefault();

        $.get( $(this).find('a').attr('href'),
            function( data ){
                $('#start-recording').hide();
                $('#stop-recording').show();
            });
    });

    $('#stop-recording').click( function( event ){
        $(this).hide();
        $('#start-recording').show();
    });

})
