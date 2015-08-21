require 'sinatra'

get '/' do
    <<-EOHTML
    <html>
        <body>
            <input id="my-input" type="text">
            <button id="insert">Insert into DOM</button>

            <div id="container">
            </div>

            <script>
               document.getElementById('insert').addEventListener('click', function() {
                    document.getElementById("container").innerHTML =
                        document.getElementById("my-input").value;
               });
            </script>
        </body>
    </html>
    EOHTML
end
