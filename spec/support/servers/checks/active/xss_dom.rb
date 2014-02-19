require 'sinatra'
require 'sinatra/contrib'

get '/onsubmit' do
    <<-EOHTML
<html>
    <script>
        function submitForm() {
            document.getElementById("container").innerHTML =
                document.getElementById("my-input").value;
        }
    </script>

    <body>
        <form onsubmit="submitForm();return false;">
            <input id="my-input" name="my-input" />
        </fom>

        <div id="container">
        </div>
    </body>
</html>
    EOHTML
end

get '/onkeypress' do
    <<-EOHTML
<html>
    <script>
        function onKeyPress() {
            document.getElementById("container").innerHTML =
                document.getElementById("my-input").value;
        }
    </script>

    <body>
        <form>
            <input onkeypress="onKeyPress();" id="my-input" name="my-input" />
        </fom>

        <div id="container">
        </div>
    </body>
</html>
    EOHTML
end

get '/onchange' do
    <<-EOHTML
<html>
    <script>
        function onChange() {
            document.getElementById("container").innerHTML =
                document.getElementById("my-input").value;
        }
    </script>

    <body>
        <form>
            <input onchange="onChange();" id="my-input" name="my-input" />
        </fom>

        <div id="container">
        </div>
    </body>
</html>
    EOHTML
end
