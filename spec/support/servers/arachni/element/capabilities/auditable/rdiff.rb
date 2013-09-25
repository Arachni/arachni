require 'sinatra'
require 'sinatra/contrib'
set :logging, false

get '/true' do
    out = case params[:rdiff]
        when 'blahbad'
            'Could not find any results, bugger off!'
        when 'blahgood', 'blah'
            '1 item found: Blah blah blah...'
        else
            'No idea what you want mate...'
    end

    <<-EOHTML
    #{rand( 9999999 )}
    <a href='?rdiff=blah'>Inject here</a>
    #{out}
EOHTML
end

get '/false' do
    out = case params[:rdiff]
        when 'blahgood', 'blahbad'
            'Could not find any results, bugger off!'
        when 'blah'
            '1 item found: Blah blah blah...'
        else
            'No idea what you want mate...'
    end

    <<-EOHTML
    #{rand( 9999999 )}
    <a href='?rdiff=blah'>Inject here</a>
    #{out}
EOHTML
end

get '/timeout' do
    out = case params[:rdiff]
              when 'blahbad'
                  'Could not find any results, bugger off!'
              when 'blahgood', 'blah'
                  sleep 2
                  '1 item found: Blah blah blah...'
              else
                  'No idea what you want mate...'
          end

    <<-EOHTML
    #{rand( 9999999 )}
    <a href='?rdiff=blah'>Inject here</a>
    #{out}
    EOHTML
end

get '/empty' do
    empty = false
    out = case params[:rdiff]
              when 'blahbad'
                  'Could not find any results, bugger off!'
              when 'blahgood', 'blah'
                  '1 item found: Blah blah blah...'
              else
                  empty = true
                  'No idea what you want mate...'
          end

    next '' if empty

    <<-EOHTML
    #{rand( 9999999 )}
    <a href='?rdiff=blah'>Inject here</a>
    #{out}
    EOHTML
end
