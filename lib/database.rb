opts = Arachni::Options.instance
require opts.dir['lib'] + 'database/base'
require opts.dir['lib'] + 'database/queue'
require opts.dir['lib'] + 'database/hash'
