require 'sinatra'
require 'sinatra/contrib'

get '/' do
    <<EOHTML
    <html>
    </html>
EOHTML
end

JS_LIB = "#{File.dirname( __FILE__ )}/"

get '/jquery.js' do
    content_type 'text/javascript'
    IO.read "#{JS_LIB}/jquery-2.0.3.js"
end

get '/jquery.cookie.js' do
    content_type 'text/javascript'
    IO.read "#{JS_LIB}/jquery.cookie.js"
end

get '/angular.js' do
    content_type 'text/javascript'
    IO.read "#{JS_LIB}/angular-1.2.8.js"
end

get '/angular-route.js' do
    content_type 'text/javascript'
    IO.read "#{JS_LIB}/angular-route.js"
end

get '/data_trace/taint_depth/4' do
    <<HTML
<html>
    <head>
        <script>
            function process( data ) {}
            process(
                {
                    d2: [
                        '#{params[:taint]}'
                    ],
                }
            );
        </script>
    <head>
</html>
HTML
end

get '/data_trace/taint_depth/5' do
    <<HTML
<html>
    <head>
        <script>
            function process( data ) {}
            process(
                {
                    d2: [
                        d4: {
                            '#{params[:taint]}'
                        }
                    ],
                }
            );
        </script>
    <head>
</html>
HTML
end

get '/data_trace/XMLHttpRequest.open' do
    <<HTML
<html>
    <head>
        <script>
            ajax = new XMLHttpRequest();
            ajax.open( 'GET', "/?taint=#{params[:taint]}", true );
            ajax.send();
        </script>
    <head>
</html>
HTML
end

get '/data_trace/XMLHttpRequest.send' do
    <<HTML
<html>
    <head>
        <script>
            ajax = new XMLHttpRequest();
            ajax.open( 'POST', '/', true );
            ajax.send( "taint=#{params[:taint]}" );
        </script>
    <head>
</html>
HTML
end

get '/data_trace/XMLHttpRequest.setRequestHeader' do
    <<HTML
<html>
    <head>
        <script>
            ajax = new XMLHttpRequest();
            ajax.open( 'POST', '/', true );
            ajax.setRequestHeader( 'X-My-Header', "stuff-#{params[:taint]}" )
            ajax.send();
        </script>
    <head>
</html>
HTML
end

get '/data_trace/multiple-taints' do
    <<-EOHTML
    <html>

        <body>
        </body>

        <script type="text/javascript">
            function process( data ) {}
            process({ my_data11: 'blah11', input11: '#{params[:taint1]}' });
            process({ my_data12: 'blah12', input12: '#{params[:taint1]}' });

            process({ my_data21: 'blah21', input21: '#{params[:taint2]}' });
            process({ my_data22: 'blah22', input22: '#{params[:taint2]}' });
        </script>
    </html>
    EOHTML
end

get '/data_trace/user-defined-global-functions' do
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

%w(escape unescape encodeURIComponent decodeURIComponent encodeURI decodeURI).each do |function|
    get "/data_trace/window.#{function}" do
        <<-EOHTML
    <html>

        <script type="text/javascript">
            #{function}('#{params[:taint]}');
        </script>
    </html>
        EOHTML
    end

end

get '/data_trace/AngularJS/$http.delete' do
    <<-EOHTML
<html ng-app>
    <script src="/angular.js"></script>

    <script>
        angular.element(document).ready(function() {
            angular.element(document.querySelectorAll('[ng-app]')[0])
                .injector().get('$http').delete( '/#{params[:taint]}' );
        });
    </script>
</html>
    EOHTML
end

get '/data_trace/AngularJS/$http.head' do
    <<-EOHTML
<html ng-app>
    <script src="/angular.js"></script>

    <script>
        angular.element(document).ready(function() {
            angular.element(document.querySelectorAll('[ng-app]')[0])
                .injector().get('$http').head( '/#{params[:taint]}' );
        });
    </script>
</html>
    EOHTML
end

get '/data_trace/AngularJS/$http.jsonp' do
    <<-EOHTML
<html ng-app>
    <script src="/angular.js"></script>

    <script>
        angular.element(document).ready(function() {
            angular.element(document.querySelectorAll('[ng-app]')[0])
                .injector().get('$http').jsonp( '/jsonp-#{params[:taint]}' );
        });
    </script>
</html>
    EOHTML
end

get '/data_trace/AngularJS/$http.get' do
    <<-EOHTML
<html ng-app>
    <script src="/angular.js"></script>

    <script>
        angular.element(document).ready(function() {
            angular.element(document.querySelectorAll('[ng-app]')[0])
                .injector().get('$http').get( '/#{params[:taint]}' );
        });
    </script>
</html>
    EOHTML
end

get '/data_trace/AngularJS/$http.put' do
    <<-EOHTML
<html ng-app>
    <script src="/angular.js"></script>

    <script>
        angular.element(document).ready(function() {
            angular.element(document.querySelectorAll('[ng-app]')[0])
                .injector().get('$http').put( '/', 'Stuff #{params[:taint]}' );
        });
    </script>
</html>
    EOHTML
end

get '/data_trace/AngularJS/$http.post' do
    <<-EOHTML
<html ng-app>
    <script src="/angular.js"></script>

    <script>
        angular.element(document).ready(function() {
            angular.element(document.querySelectorAll('[ng-app]')[0])
                .injector().get('$http').post( '/', '', { params: { stuff: 'Stuff #{params[:taint]}' } } );
        });
    </script>
</html>
    EOHTML
end

get '/data_trace/AngularJS/ngRoute/' do
    <<-EOHTML
<!doctype html>
<html ng-app="project">
    <head>
        <script src="/angular.js"></script>
        <script src="/angular-route.js"></script>
        <script src="project.js?taint=#{params[:taint]}"></script>
    </head>
    <body>
        <h2>JavaScript Projects</h2>
        <div ng-view></div>
    </body>

    <script>
        angular.element(document).ready(function() {
            angular.element(document).scope().$apply(function() {});
        });
    </script>
</html>
    EOHTML
end

get '/data_trace/AngularJS/ngRoute/template.html' do
    <<-EOHTML
Blah blah blah #{params[:taint]}
    EOHTML
end

get '/data_trace/AngularJS/ngRoute/project.js' do
    content_type 'text/javascript'

    <<-EOHTML
angular.module('project', ['ngRoute'])

.config(function($routeProvider) {
    $routeProvider
        .when('/', {
            templateUrl: 'template.html?taint=#{params[:taint]}'
        })
        .otherwise({
            redirectTo:'/'
        });
});
    EOHTML
end

get '/data_trace/AngularJS.element' do
    <<-EOHTML
    <html>
        <script src="/angular.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            angular.element( '<div>Stuff ' + #{params[:taint].inspect} + '</div>' );
        </script>
    </html>
    EOHTML
end

get '/data_trace/AngularJS/jqLite.html' do
    <<-EOHTML
    <html>
        <script src="/angular.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            angular.element(document.getElementById("my-div")).html( 'Stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/AngularJS/jqLite.text' do
    <<-EOHTML
    <html>
        <script src="/angular.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            angular.element(document.getElementById("my-div")).text( 'Stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/AngularJS/jqLite.val' do
    <<-EOHTML
    <html>
        <script src="/angular.js" type="text/javascript"></script>

        <div id='my-div'>
            <input id='my-input' />
        </div>

        <script type="text/javascript">
            angular.element(document.getElementById("my-input")).val( 'Stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/AngularJS/jqLite.append' do
    <<-EOHTML
    <html>
        <script src="/angular.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            angular.element(document.getElementById("my-div")).append( 'Stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/AngularJS/jqLite.prepend' do
    <<-EOHTML
    <html>
        <script src="/angular.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            angular.element(document.getElementById("my-div")).prepend( 'Stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/AngularJS/jqLite.prop' do
    <<-EOHTML
    <html>
        <script src="/angular.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            angular.element(document.getElementById("my-div")).prop( 'stuff', 'Stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/AngularJS/jqLite.replaceWith' do
    <<-EOHTML
    <html>
        <script src="/angular.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            angular.element(document.getElementById("my-div")).replaceWith( 'Stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/jQuery.cookie' do
    <<-EOHTML
    <html>
        <script src="/jquery.js" type="text/javascript"></script>
        <script src="/jquery.cookie.js" type="text/javascript"></script>

        <script type="text/javascript">
            $.cookie( 'cname', 'mystuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/jQuery.ajax' do
    <<-EOHTML
    <html>
        <script src="/jquery.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            $.ajax( { url: '/' , data: { stuff:  'mystuff '+ #{params[:taint].inspect} } } );
        </script>
    </html>
    EOHTML
end

get '/data_trace/jQuery.get' do
    <<-EOHTML
    <html>
        <script src="/jquery.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            $.get( '/' , { stuff:  'mystuff '+ #{params[:taint].inspect} } );
        </script>
    </html>
    EOHTML
end

get '/data_trace/jQuery.post' do
    <<-EOHTML
    <html>
        <script src="/jquery.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            $.post( '/#{params[:taint]}' );
        </script>
    </html>
    EOHTML
end

get '/data_trace/jQuery.load' do
    <<-EOHTML
    <html>
        <script src="/jquery.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            $('#my-div').load( '/#{params[:taint]}' );
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

get '/data_trace/jQuery.text' do
    <<-EOHTML
    <html>
        <script src="/jquery.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            $("#my-div").text( 'Stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/jQuery.val' do
    <<-EOHTML
    <html>
        <script src="/jquery.js" type="text/javascript"></script>

        <div id='my-div'>
            <input id='my-input' />
        </div>

        <script type="text/javascript">
            $("#my-input").val( 'Stuff ' + #{params[:taint].inspect} );
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

get '/data_trace/jQuery.prepend' do
    <<-EOHTML
    <html>
        <script src="/jquery.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            $("#my-div").prepend( 'Stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/jQuery.prop' do
    <<-EOHTML
    <html>
        <script src="/jquery.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            $("#my-div").prop( 'stuff', 'Stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/jQuery.replaceWith' do
    <<-EOHTML
    <html>
        <script src="/jquery.js" type="text/javascript"></script>

        <div id='my-div'>
        </div>

        <script type="text/javascript">
            $("#my-div").replaceWith( 'Stuff ' + #{params[:taint].inspect} );
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

get '/data_trace/String.lastIndexOf' do
    <<-EOHTML
    <html>
        <script type="text/javascript">
            'my string'.lastIndexOf( 'stuff ' + #{params[:taint].inspect} );
        </script>
    </html>
    EOHTML
end

get '/data_trace/String.indexOf' do
    <<-EOHTML
    <html>
        <script type="text/javascript">
            'my string'.indexOf( 'stuff ' + #{params[:taint].inspect} );
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

get '/data_trace/CharacterData.insertData' do
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

get '/data_trace/CharacterData.appendData' do
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

get '/data_trace/CharacterData.replaceData' do
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

get '/debug' do
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

get '/eval' do
    <<-EOHTML
    <html>
        <script>
            function run() {
                return #{params[:input]};
            }

            run( 1, 2 );
        </script>
    </html>
    EOHTML
end

get '/needs-injector' do
    <<-EOHTML
    <html>
        <script>
            function onClick( some, arguments, here ) {
                #{params[:input]};
                return false;
            }
        </script>

        <form id="my_form" onsubmit="onClick(location.hash); return false;">
        </form>
    </html>
    EOHTML
end

get '/without_javascript_support' do
end
