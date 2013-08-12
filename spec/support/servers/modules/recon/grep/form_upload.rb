require 'sinatra'

get '/' do
    <<-EOHTML
        <form name="upload-form">
            <input type="file" name="upload-me">
        </form>
    EOHTML
end
