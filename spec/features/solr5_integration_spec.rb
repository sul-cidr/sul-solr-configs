require 'spec_helper'
require 'solr_wrapper'
require 'hurley'
require 'json'
require 'fileutils'
require 'securerandom'

describe "integration with solr" do
  let(:solr) { @solr }
  let(:collection) { @collection }

  before(:all) do
    @solr = SolrWrapper::Instance.new
    @solr.send(:extract)
    solr_dir = @solr.send(:solr_dir)
    test_solr_xml = File.expand_path("../../solr/solr.xml", __FILE__)
    solr_xml = File.join(solr_dir, "server/solr/solr.xml")
    contrib_dir = File.join(solr_dir, "solr-contrib")
    FileUtils.cp test_solr_xml, solr_xml
    FileUtils.mkdir contrib_dir unless File.exist? contrib_dir
    FileUtils.cp Dir.glob(File.join(solr_dir, "contrib", "analysis-extras", "**", "*.jar")), contrib_dir

    @solr.start
  end

  after(:all) do
    @solr.stop
  end

  around(:example) do |example|
    solr.with_collection(name: "#{File.basename(dir)}_#{SecureRandom.hex}", dir: dir) do |collection|
      @collection = collection
      example.run
    end
  end

  shared_examples "works in solr" do
    let(:client) do
      Hurley::Client.new("http://127.0.0.1:#{solr.port}/solr/#{collection}/")
    end

    let(:log) do
      JSON.parse(client.get("/solr/admin/info/logging?wt=json&since=0").body)['history']['docs'].drop_while { |x| x !~ /#{collection}/ }
    end

    describe "x" do
      it "has a /select" do
        response = client.get "select?q=*:*"
        expect(response).to be_success
      end

      it "logs no serious warnings" do
        salient_lines = log.reject { |x| x['message'] =~ /Creating new index/ }
        expect(salient_lines.reject { |x| x['message'] =~ /deprecated/ }).to be_empty
      end

      it "logs no deprecations" do
        salient_lines = log.select { |x| x['message'] =~ /deprecated/ }
        pending unless salient_lines.empty?

        expect(salient_lines).to be_empty
      end
    end
  end

  solr_collections.each do |name|
    describe name do
      let(:dir) { name }
      include_examples "works in solr"
    end
  end
end
