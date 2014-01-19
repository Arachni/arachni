require 'sinatra'
require 'sinatra/contrib'

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
