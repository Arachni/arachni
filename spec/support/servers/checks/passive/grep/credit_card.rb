require 'sinatra'
require 'sinatra/contrib'

NUMBERS = {
    amex:         378282246310005,
    amex_copr:    378734493671000,
    oz_bank_card: 5610591081018250,
    dinners:      30569309025904,
    discover:     6011111111111117,
    jcb:          3530111333300000,
    master:       5555555555554444,
    visa:         4111111111111111,
    pbs:          76009244561,
    paymentech:   6331101999990016
}

NUMBERS.each do |type, number|
    get "/#{type}" do
        number.to_s
    end
end

get '/' do
    NUMBERS.keys.map do |type|
        "<a href=\"#{type}\">#{type}</a> "
    end.join
end

