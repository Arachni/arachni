require 'sinatra'
require 'sinatra/contrib'

get '/true' do
    out = case params[:rdiff]
        when 'bad'
            'Could not find any results, bugger off!'
        when 'good', 'blah'
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
        when 'good', 'bad'
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
              when 'bad'
                  'Could not find any results, bugger off!'
              when 'good', 'blah'
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

get '/empty_false' do
    empty = false
    out = case params[:rdiff]
              when 'bad'
                  empty = true
                  'Could not find any results, bugger off!'
              when 'good', 'blah'
                  '1 item found: Blah blah blah...'
              else
                  'No idea what you want mate...'
          end

    next '' if empty

    <<-EOHTML
#{rand( 9999999 )}
    <a href='?rdiff=blah'>Inject here</a>
    #{out}
    EOHTML
end

get '/empty_true' do
    empty = false
    out = case params[:rdiff]
              when 'bad'
                  'Could not find any results, bugger off!'
              when 'good', 'blah'
                  empty = true
                  '1 item found: Blah blah blah...'
              else
                  'No idea what you want mate...'
          end

    next '' if empty

    <<-EOHTML
    #{rand( 9999999 )}
    <a href='?rdiff=blah'>Inject here</a>
    #{out}
    EOHTML
end

get '/non200_true' do
    empty = false
    out = case params[:rdiff]
              when 'bad'
                  'Could not find any results, bugger off!'
              when 'good', 'blah'
                  status 403
                  '1 item found: Blah blah blah...'
              else
                  'No idea what you want mate...'
          end

    next '' if empty

    <<-EOHTML
#{rand( 9999999 )}
    <a href='?rdiff=blah'>Inject here</a>
    #{out}
    EOHTML
end

get '/non200_false' do
    empty = false
    out = case params[:rdiff]
              when 'bad'
                  status 403
                  'Could not find any results, bugger off!'
              when 'good', 'blah'
                  '1 item found: Blah blah blah...'
              else
                  'No idea what you want mate...'
          end

    next '' if empty

    <<-EOHTML
#{rand( 9999999 )}
    <a href='?rdiff=blah'>Inject here</a>
    #{out}
    EOHTML
end


get '/unstable' do
    @@calls ||= 0
    @@calls  += 1
    empty    = false

    out = case params[:rdiff]
              when 'bad'
                  'Could not find any results, bugger off!' * 100 if @@calls >= 2
              when 'good', 'blah'
                  '1 item found: Blah blah blah...'
              else
                  'No idea what you want mate...'
          end

    next '' if empty

    <<-EOHTML
#{rand( 9999999 )}
    <a href='?rdiff=blah'>Inject here</a>
    #{out}
    EOHTML
end
