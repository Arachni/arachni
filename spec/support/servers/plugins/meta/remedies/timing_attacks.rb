require 'sinatra'

# stupid to way to pretend vulnerability for :os_cmd_injection_timing
def eval( str )
    return if !str.to_s.strip.start_with?( 'ping' )

    if delay = str.to_s.gsub( /\D/, ' ' ).split( ' ' ).uniq.last
        sleep delay.to_i
    end
end

get '/' do
    <<-HTML
        <form action='/trusted'>
            <input name="trusted_input"/>
        </form>

        <form action='/untrusted'>
            <input name="untrusted_input"/>
        </form>
    HTML
end

get '/trusted' do
    eval( params['trusted_input'] )
end

get '/untrusted' do
    sleep( 4 )
    eval( params['untrusted_input'] )
end
