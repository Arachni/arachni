class ArachniMetareport
    
    attr_accessor :url
    attr_accessor :var
    attr_accessor :params
    attr_accessor :method
    attr_accessor :exploit
    attr_accessor :headers
    
    def initialize( opts = {} )
        opts.each {
            |k, v|
            begin
                send( "#{k.to_s.downcase}=", v )
            rescue Exception => e
            end
        }
    end
    
end
