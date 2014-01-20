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
