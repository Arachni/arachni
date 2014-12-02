require 'sinatra'

post '/submit' do
    request.body.read
end

get '/forms' do
    <<EOHTML
<html>
    <body>
        <form method="post" action="/form" name="my_form">
            <p>
              <input type="text" name="form_input_1" value="form_val_1">
              <input type="text" name="form_input_2" value="form_val_2">
              <input type="submit">
            </p>
        </form>

        <form method="get" action="/form_2" name="my_form_2">
            <input type="text" name="form_2_input_1" value="form_2_val_1">

    </body>
</html>
EOHTML
end
