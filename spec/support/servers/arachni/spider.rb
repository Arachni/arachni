require 'sinatra'
require 'sinatra/contrib'

get '/' do
    <<EOHTML
    <a href='/this_does_not_exist'> 404 </a>
EOHTML
end

get '/fail_4_times' do
    @@tries ||= 0
    @@tries += 1

    if @@tries <= 5
        # Return a 0 error code.
        0
    else
        'Stuff'
    end
end

get '/fail' do
    # Return a 0 error code.
    0
end

get '/skip' do
    'Skip me!'
end

get '/sleep' do
    sleep 2
    <<EOHTML
    <a href='/something'>Stuff</a>
EOHTML
end

get '/something' do
    'Stuff'
end

get '/path_params' do
    <<EOHTML
    <a href='/something;test=stuff'>path_params</a>
    <a href='/something;test=stuff1'>path_params</a>
    <a href='/something;test=stuff2'>path_params</a>
    <a href='/something;test=stuff3'>path_params</a>
EOHTML
end

get '/foreign_domain' do
    <<EOHTML
    <a href='/goto_foreign_domain'>goto_foreign_domain</a>
EOHTML
end

get '/goto_foreign_domain' do
    redirect 'http://google.com/'
end

get '/relative_redirect' do
    headers 'Location' => '/stacked_redirect'
    301
end

get '/redirect' do
    redirect '/'
end

get '/skip_redirect' do
    redirect 'http://google.com'
end

get '/stacked_redirect' do
    redirect '/stacked_redirect1'
end

get '/stacked_redirect1' do
    redirect '/stacked_redirect2'
end

get '/stacked_redirect2' do
    redirect '/stacked_redirect3'
end

get '/stacked_redirect3' do
    redirect '/stacked_redirect4'
end

get '/stacked_redirect4' do
end

get '/redundant' do
    <<EOHTML
    <a href='/redundant/1'>Redundant 1</a>
EOHTML
end

get '/redundant/1' do
    <<EOHTML
    <a href='/redundant/2'>Redundant 2</a>
EOHTML
end

get '/redundant/2' do
    <<EOHTML
    <a href='/redundant/3'>Redundant 3</a>
EOHTML
end

get '/redundant/3' do
    'End of the line.'
end

get '/a_pushed_path' do
end

get '/some-path blah! %25&$' do
    <<EOHTML
    <a href='/another weird path %25"&*[$)'> Weird </a>
EOHTML
end

get '/another weird path %25"&*[$)' do
    'test'
end

get '/loop' do
    <<EOHTML
    <a href='/loop_back'> Loop </a>
EOHTML
end

get '/loop_back' do
    <<EOHTML
    <a href='/loop'> Loop </a>
EOHTML
end

get '/with_cookies' do
    cookies['my_cookie'] = 'my value'
    <<EOHTML
    <a href='/with_cookies2'> This needs a cookie </a>
EOHTML
end

get '/with_cookies2' do
    if cookies['my_cookie'] == 'my value'
        <<-EOHTML
        <a href='/with_cookies3'> This needs a cookie </a>
    EOHTML
    end
end

get '/with_cookies3' do
end

get '/auto-redundant' do
    str = ''
    10.times do
        str += <<-EOHTML
        <a href='/auto-redundant?stuff=#{rand( 999 )}'>Stuff</a>
    EOHTML
    end

    10.times do
        str += <<-EOHTML
        <a href='/auto-redundant?stuff=#{rand( 999 )}&ha=#{rand( 999 )}'>Stuff</a>
        EOHTML
    end

    str
end

get '/lots_of_paths' do
    html = ''

    50.times do |i|
        html << <<-EOHTML
        <a href='/lots_of_paths/#{i}'>Stuff</a>
        EOHTML
    end
    html
end

get '/lots_of_paths/:id' do |id|
    html = ''

    100.times do |i|
        html << <<-EOHTML
        <a href='/lots_of_paths/#{id}/#{i}'>Stuff</a>
        EOHTML
    end
    html
end

get '/lots_of_paths/:id/:id2' do |id, id2|
    html = ''

    500.times do |i|
        html << <<-EOHTML
        <a href='/lots_of_paths/#{id}/#{id2}/#{id}'>Stuff</a>
        EOHTML
    end
    html
end

get '/lots_of_paths/:id/:id2/:id3' do
    'End of the line...'
end
