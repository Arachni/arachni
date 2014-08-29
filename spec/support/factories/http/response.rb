Factory.define :response do
    Arachni::HTTP::Response.new(
        request: Factory.create( :request ),
        code:    200,
        time:    1.1,
        url:     'http://a-url.com/?myvar=my%20value',
        body:    '<a href="http://a-url.com/path?var1=1">1</a>
                <a href="http://a-url.com/a/path?var2=2">2</a>
                <a href="http://a-url.com/another/path/?var3=3">3</a>

                <form> <input name=""/> </form>',
        headers: {
            'res-header-name' => 'res header value',
            'Set-Cookie'      => 'cookiename=cokie+value'
        }
    )
end

Factory.define :html_response do
    Arachni::HTTP::Response.new(
        url:     'http://test.com',
        body:    Faker::Lorem.paragraph( 3 ),
        time:    1.2,
        request: Factory.create( :request ),
        headers: {
            'Content-Type' => 'text/html',
            'Set-Cookie'   => 'cname=cval'
        }
    )
end

Factory.define :binary_response do
    Arachni::HTTP::Response.new(
        url:     'http://test.com',
        body:    "\0\0\0\0\0\1\1\0",
        time:    1.3,
        request: Factory.create( :request ),
        headers: {
            'Content-Type' => 'stuff/bin'
        }
    )
end
