Factory.define :page do
    Arachni::Page.new(
        response: Factory.create( :response ),
        dom: {
            transitions: [ page: :load ]
        }
    )
end
