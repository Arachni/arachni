require 'sinatra'
require 'sinatra/contrib'

JS_LIB = "#{File.dirname( __FILE__ )}/javascript/"

get '/jquery.js' do
    content_type 'text/javascript'
    IO.read "#{JS_LIB}/jquery-2.0.3.js"
end

get '/data_trace/global-functions' do
    <<-EOHTML
    <html>

        <body>
        </body>

        <script type="text/javascript">
            function process( data ) {}
            process({ my_data: 'blah', input: '#{params[:taint]}' });
        </script>
    </html>
    EOHTML
end

get '/data_trace/jQuery.html' do
    <<-EOHTML
    <html>
        <script src="/jquery.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            $("#my-div").html( 'Stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/jQuery.append' do
    <<-EOHTML
    <html>
        <script src="/jquery.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            $("#my-div").append( 'Stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/jQuery.before' do
    <<-EOHTML
    <html>
        <script src="/jquery.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            $("#my-div").before( 'Stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/HTMLElement.insertAdjacentHTML' do
    <<-EOHTML
    <html>
        <body>
            <div id='my-div'></div>
        </body>

        <script type="text/javascript">
            element = document.getElementById('my-div');
            element.insertAdjacentHTML( 'AfterBegin', 'stuff ' + #{params[:taint].inspect} + ' more stuff' );
        </script>
    </html>
    EOHTML
end

get '/data_trace/Element.setAttribute' do
    <<-EOHTML
    <html>
        <body>
            <div id='my-div'></div>
        </body>

        <script type="text/javascript">
            element = document.getElementById('my-div');
            element.setAttribute( 'my-attribute', 'stuff ' + #{params[:taint].inspect} + ' more stuff' );
        </script>
    </html>
    EOHTML
end

get '/data_trace/String.replace' do
    <<-EOHTML
    <html>
        <script type="text/javascript">
            'my string'.replace( 'my', #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/String.concat' do
    <<-EOHTML
    <html>
        <script type="text/javascript">
            'my string'.concat( 'stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/Document.createTextNode' do
    <<-EOHTML
    <html>
        <script type="text/javascript">
            document.createTextNode( 'node ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/HTMLDocument.writeln' do
    <<-EOHTML
    <html>
        <script type="text/javascript">
            document.writeln( 'Stuff here blah ' + #{params[:taint].inspect} + ' more stuff nlahblah...' );
        </script>
    </html>
    EOHTML
end

get '/data_trace/HTMLDocument.write' do
    <<-EOHTML
    <html>
        <script type="text/javascript">
            document.write( 'Stuff here blah ' + #{params[:taint].inspect} + ' more stuff nlahblah...' );
        </script>
    </html>
    EOHTML
end

get '/data_trace/Text.replaceWholeText' do
    <<-EOHTML
    <html>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            var text = document.createTextNode( "New List Item 1" );
            text.replaceWholeText( 'Stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/Text.insertData' do
    <<-EOHTML
    <html>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            var text = document.createTextNode( "New List Item 1" );
            text.insertData( 'Stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/Text.appendData' do
    <<-EOHTML
    <html>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            var text = document.createTextNode( "New List Item 1" );
            text.appendData( 'Stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/Text.replaceData' do
    <<-EOHTML
    <html>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            var text = document.createTextNode( "New List Item 1" );
            text.replaceData( 0, 0, 'Stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/timeout-tracker' do
    <<HTML
    <script>
        document.cookie = "timeout=pre"

        setTimeout( function( name, value ){
            document.cookie = name + "=post-" + value
        }, 1000, 'timeout1', 1000 )

        setTimeout( function( name, value ){
            document.cookie = name + "=post-" + value
        }, 1500, 'timeout2', 1500 )

        setTimeout( function( name, value ){
            document.cookie = name + "=post-" + value
        }, 2000, 'timeout3', 2000 )
    </script>
HTML
end

get '/interval-tracker' do
    <<HTML
    <script>
        document.cookie = "timeout=pre"
        setInterval( function( name, value ){
            document.cookie = name + "=post-" + value
        }, 2000, 'timeout1', 2000 )
    </script>
HTML
end

get '/debugging_data' do
    <<-EOHTML
    <html>
        <script>
            function onClick( some, arguments, here ) {
                #{params[:input]};
                return false;
            }
        </script>

        <form id="my_form" onsubmit="onClick('some-arg', 'arguments-arg', 'here-arg'); return false;">
        </form>
    </html>
    EOHTML
end
