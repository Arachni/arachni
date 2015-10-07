require 'spec_helper'

describe WEBrick::Cookie do

    describe '.parse_set_cookie' do
        it 'includes the httponly attribute' do
            str = "cookie2=val2; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Path=/; Domain=.foo.com; HttpOnly"
            expect(WEBrick::Cookie.parse_set_cookie( str ).httponly).to be_truthy

            str = "cookie2=val2; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Path=/; Domain=.foo.com"
            expect(WEBrick::Cookie.parse_set_cookie( str ).httponly).to be_falsey
        end
    end

end
