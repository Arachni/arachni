require 'sinatra'

get '/' do
    <<-EOHTML
    <html>
        <script>
            function handleOnInput() {
                document.getElementById("container").innerHTML =
                    document.getElementById("my-input").value;
            }
        </script>

        <body>
            <input oninput="handleOnInput();" id="my-input" name="my-input" value="1" />

            <div id="container">
            </div>
        </body>
    </html>
    EOHTML
end
