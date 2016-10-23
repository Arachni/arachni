require 'spec_helper'

describe Arachni::Parser::Document do
    let(:options) do
        {}
    end
    subject { Arachni::Parser.parse( html, options ) }
    let(:html) do
        <<-EOHTML
        <html>
            <div id="my-id">
                <!-- My comment -->
                <p class="my-class">
                    <a href="/stuff">Stuff</a>
                </p>

                My text
            </div>
        </html>
        EOHTML
    end

    describe '#name' do
        it 'returns self' do
            expect(subject.name).to be :document
        end
    end

    describe '#to_html' do
        it 'generates HTML code from nodes' do
            html = <<-EOHTML
<!DOCTYPE html>
<html>
  <div id="my-id">
    <!-- My comment -->
    <p class="my-class">
      <a href="/stuff">
        Stuff
      </a>
    </p>
    My text
  </div>
</html>
            EOHTML

            expect(subject.to_html.strip).to eq html.strip
        end
    end
end
