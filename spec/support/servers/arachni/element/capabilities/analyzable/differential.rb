require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/streaming'

helpers Sinatra::Streaming

get '/true' do
    out = case params[:input]
        when 'bad'
            'Could not find any results, bugger off!'
        when 'good', 'blah'
            '1 item found: Blah blah blah...'
        else
            'No idea what you want mate...'
    end

    <<-EOHTML
    #{rand( 9999999 )}
    <a href='?input=blah'>Inject here</a>
    #{out}
EOHTML
end

get '/false' do
    out = case params[:input]
        when 'good', 'bad'
            'Could not find any results, bugger off!'
        when 'blah'
            '1 item found: Blah blah blah...'
        else
            'No idea what you want mate...'
    end

    <<-EOHTML
    #{rand( 9999999 )}
    <a href='?input=blah'>Inject here</a>
    #{out}
EOHTML
end

get '/timeout' do
    out = case params[:input]
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
    <a href='?input=blah'>Inject here</a>
    #{out}
    EOHTML
end

get '/empty_false' do
    empty = false
    out = case params[:input]
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
    <a href='?input=blah'>Inject here</a>
    #{out}
    EOHTML
end

get '/empty_true' do
    empty = false
    out = case params[:input]
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
    <a href='?input=blah'>Inject here</a>
    #{out}
    EOHTML
end

get '/non200_true' do
    empty = false
    out = case params[:input]
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
    <a href='?input=blah'>Inject here</a>
    #{out}
    EOHTML
end

get '/non200_false' do
    empty = false
    out = case params[:input]
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
    <a href='?input=blah'>Inject here</a>
    #{out}
    EOHTML
end


get '/unstable' do
    @@calls ||= 0
    @@calls  += 1
    empty    = false

    out = case params[:input]
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
    <a href='?input=blah'>Inject here</a>
    #{out}
    EOHTML
end

get '/partial_false' do
    partial = false
    out = case params[:input]
              when 'bad'
                  partial = true
                  'Could not find any results, bugger off!'
              when 'good', 'blah'
                  '1 item found: Blah blah blah...'
              else
                  'No idea what you want mate...'
          end

    body = <<-EOHTML
        #{rand( 9999999 )}
        <a href='?input=blah'>Inject here</a>
        #{out}
    EOHTML

    if partial
        [ 200, { 'Content-Length' => '1000' }, body ]
    else
        body
    end
end

get '/partial_true' do
    partial = false
    out = case params[:input]
              when 'bad'
                  'Could not find any results, bugger off!'
              when 'good', 'blah'
                  partial = true
                  '1 item found: Blah blah blah...'
              else
                  'No idea what you want mate...'
          end

    body = <<-EOHTML
        #{rand( 9999999 )}
        <a href='?input=blah'>Inject here</a>
        #{out}
    EOHTML

    if partial
        [ 200, { 'Content-Length' => '1000' }, body ]
    else
        body
    end
end

get '/partial_stream_false' do
    partial = false
    out = case params[:input]
              when 'bad'
                  partial = true
                  'Could not find any results, bugger off!'
              when 'good', 'blah'
                  '1 item found: Blah blah blah...'
              else
                  'No idea what you want mate...'
          end

    stream do |s|
        s.puts <<-EOHTML
            #{rand( 9999999 )}
            <a href='?input=blah'>Inject here</a>
        EOHTML

        s.close if partial

        s.puts out
        s.flush
    end
end

get '/partial_stream_true' do
    partial = false
    out = case params[:input]
              when 'bad'
                  'Could not find any results, bugger off!'
              when 'good', 'blah'
                  partial = true
                  '1 item found: Blah blah blah...'
              else
                  'No idea what you want mate...'
          end

    stream do |s|
        s.puts <<-EOHTML
            #{rand( 9999999 )}
            <a href='?input=blah'>Inject here</a>
        EOHTML

        s.close if partial

        s.puts out
        s.flush
    end
end
