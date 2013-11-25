require 'sinatra'
require_relative '../check_server'

def root
    File.expand_path( File.dirname( __FILE__ ) )
end

get '/' do
    <<-EOHTML
        <a href="/some/path.crap?input=bloo">Path</a>
    EOHTML
end

get '/some/path.crap' do
    <<-EOHTML
        Blah blah blah...#{params['input']}
    EOHTML
end

get '/some*' do
    req = URI.decode( env['PATH_INFO'].gsub( '/some', root ) ).gsub( '\\', '/' )
    req << '/' if !req.end_with?( '/' )

    #ap req
    if File.directory?( req )
        Dir.glob( req + '*' ).join( '<br/>' )
    elsif !File.exists?( req )
        'Does not exist'
    end
end
