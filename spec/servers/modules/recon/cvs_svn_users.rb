require 'sinatra'
require 'sinatra/contrib'

KEYWORDS = {
    id:     '$Id: https-test.pl 1081 2008-09-30 19:03:23Z john $',
    locker: '$Locker: markd $',
    author: '$Author: markd $',
    header: '$Header: /cvsweb/cvs-guide/keyword.html,v 1.3 1999/12/23 21:59:22 markd Exp $ '
}

KEYWORDS.each do |type, string|
    get "/#{type}" do
        string
    end
end

get '/' do
    KEYWORDS.keys.map do |type|
        "<a href=\"#{type}\">#{type}</a> "
    end.join
end
