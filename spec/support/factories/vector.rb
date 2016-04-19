Factory.define :vector do |type = :Form|
    Arachni::Element.const_get( type ).new( url: 'http://test.com', inputs: { stuff: 1 } )
end

Factory.define :passive_vector do
    v = Factory[:vector]
    v.affected_input_name  = :stuff
    v.affected_input_value = 2
    v
end

Factory.define :active_vector do
    v = Factory[:passive_vector]
    v.seed = 2
    v
end

Factory.define :unique_active_vector do |type = :Form|
    v = Factory.create(:vector, type)
    v.affected_input_name  = rand(9999).to_s + rand(9999).to_s
    v.affected_input_value = 2
    v.seed                 = 2
    v
end

Factory.define :body_vector do
    Arachni::Element::Body.new Factory[:page].url
end

Factory.define :server_vector do
    Arachni::Element::Server.new Factory[:response].url
end

Factory.define :path_vector do
    Arachni::Element::Path.new Factory[:response].url
end
