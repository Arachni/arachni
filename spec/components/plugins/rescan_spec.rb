require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before ( :all ) do
        options.do_not_crawl
        options.url = url
        options.audit :links
        framework.modules.load :xss
    end

    it 'logs safe and vuln URLs accordingly' do
        afr = fixtures_path + 'rescan.afr.tpl'
        updated = fixtures_path + 'rescan.afr'

        yaml_load( IO.read( afr ) ).save( updated )
        options.plugins[name_from_filename] = { 'afr' => updated }

        run
        framework.modules.issues.should be_any
        framework.modules.issues.first.var.should == 'input'

        File.delete( updated )
    end
end
