require 'sinatra'

get '/' do
    <<-EOHTML
    <html>
        <body>
            <input id="my-input" type="text" value="stuff">
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

get '/without-buttons' do
    <<-EOHTML
    <html>
        <body>
            <input id="insert" value="stuff">
            <textarea id="my-input" type="text" value="stuff">stuff</textarea>

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

get '/button/without-inputs' do
    <<-EOHTML
    <html>
        <body>
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

get '/button/input/type/text/with_events' do
    <<-EOHTML
    <html>
        <body>
            <input type="text" id="my-input" value="stuff">
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

get '/button/input/type/none/with_events' do
    <<-EOHTML
    <html>
        <body>
            <input id="my-input" value="stuff">
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

get '/button/input/without_events' do
    <<-EOHTML
    <html>
        <body>
            <input id="my-input" type="text" value="stuff">
            <button id="insert">Insert into DOM</button>

            <div id="container">
            </div>
        </body>
    </html>
    EOHTML
end

get '/button/textarea/with_events' do
    <<-EOHTML
    <html>
        <body>
            <textarea id="my-input" type="text" value="stuff">stuff</textarea>
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

get '/button/textarea/without_events' do
    <<-EOHTML
    <html>
        <body>
            <textarea id="my-input" type="text" value="stuff">stuff</textarea>
            <button id="insert">Insert into DOM</button>

            <div id="container">
            </div>
        </body>
    </html>
    EOHTML
end

get '/input-button/without-input' do
    <<-EOHTML
    <html>
        <body>
            <input type="button" id="insert" value="Insert into DOM" />

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

get '/input-button/input/with_events' do
    <<-EOHTML
    <html>
        <body>
            <input id="my-input" type="text" value="stuff" />
            <input type="button" id="insert" value="Insert into DOM" />

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

get '/input-button/input/without_events' do
    <<-EOHTML
    <html>
        <body>
            <input id="my-input" type="text" value="stuff" />
            <input type="button" id="insert" value="Insert into DOM" />
        </body>
    </html>
    EOHTML
end

get '/input-button/textarea/with_events' do
    <<-EOHTML
    <html>
        <body>
            <textarea id="my-input" type="text">stuff</textarea>
            <input type="button" id="insert" value="Insert into DOM" />

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

get '/input-button/textarea/without_events' do
    <<-EOHTML
    <html>
        <body>
            <textarea id="my-input" type="text">stuff</textarea>
            <input type="button" id="insert" value="Insert into DOM" />
        </body>
    </html>
    EOHTML
end

get '/input-submit/without-input' do
    <<-EOHTML
    <html>
        <body>
            <input type="submit" id="insert" value="Insert into DOM" />

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

get '/input-submit/input/with_events' do
    <<-EOHTML
    <html>
        <body>
            <input id="my-input" type="text" value="stuff" />
            <input type="submit" id="insert" value="Insert into DOM" />

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

get '/input-submit/input/without_events' do
    <<-EOHTML
    <html>
        <body>
            <input id="my-input" type="text" value="stuff" />
            <input type="submit" id="insert" value="Insert into DOM" />
        </body>
    </html>
    EOHTML
end

get '/input-submit/textarea/with_events' do
    <<-EOHTML
    <html>
        <body>
            <textarea id="my-input" type="text">stuff</textarea>
            <input type="submit" id="insert" value="Insert into DOM" />

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

get '/input-submit/textarea/without_events' do
    <<-EOHTML
    <html>
        <body>
            <textarea id="my-input" type="text">stuff</textarea>
            <input type="submit" id="insert" value="Insert into DOM" />
        </body>
    </html>
    EOHTML
end
