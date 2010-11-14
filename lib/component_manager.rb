
module Arachni

class ComponentManager < Hash

    WILDCARD = '*'
    EXCLUDE  = '-'

    def initialize( lib, parent )
        @lib    = lib
        @parent = parent
    end

    def load( components )
        parse( components ).each {
            |component|
            self.[]( component )
        }
    end

    def parse( components )
        unload = []
        load   = []

        components.each {
            |component|
            if component[0] == EXCLUDE
                component[0] = ''
                unload << component
            end
        }

        if( !components.include?( WILDCARD ) )

            avail_components  = available(  )

            components.each {
                |component|
                if( !avail_components.include?( component ) )
                      raise( Arachni::Exceptions::ModNotFound,
                          "Error: Component #{component} wasn't found." )
                end
            }

            # recon modules should be loaded before audit ones
            # and ls_available() honors that
            avail_components.map {
                |component|
                load << component if components.include?( component )
            }
        else
            available(  ).map {
                |component|
                load << component
            }
        end

        return load - unload
    end

    def []( name )

        return fetch( name ) if include?( name )

        paths.each {
            |path|

            next if name != path_to_name( path )

            ::Kernel::load( path )
             self[name] = @parent.const_get( @parent.constants[-1] )
        }

        return fetch( name ) rescue nil
    end

    def available
        components = []
        paths.each {
            |path|
            name = path_to_name( path )
            components << name
        }
        return components
    end

    def name_to_path( name )
        paths.each {
            |path|
            return path if name == path_to_name( path )
        }
        return
    end

    def path_to_name( path )
        File.basename( path, '.rb' )
    end

    def paths
        cpaths = paths = Dir.glob( File.join( "#{@lib}**", "*.rb" ) )
        return paths.reject {
            |path|
            helper?( paths, path )
        }
    end

    private

    def helper?( paths, path )
        path = File.dirname( path )
        paths.each {
            |cpath|
            return true if path == File.dirname( cpath ) + '/' + path_to_name( path )
        }

        return false
    end

end

end
