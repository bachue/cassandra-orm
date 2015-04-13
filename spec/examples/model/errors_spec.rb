describe CassandraORM::Model::Persist do
  before :each do
    Upgrade = Class.new CassandraORM::Model do
      set_primary_key :product_name, :version
      attributes :minimal_version, :url, :changelog
    end
  end

  let(:upgrade) { Upgrade.new(product_name: 'cassandra', version: 1, minimal_version: 0,
                              url: 'http://cassandra.apache.org', changelog: 'Changelog for 1.0').tap(&:save) }

  it 'should translate errors' do
    upgrade.errors.append :product_name, :exact_length, exact: 10
    upgrade.errors.append :product_name, :type, type: String
    upgrade.errors.append :version, :numeric
    upgrade.errors.append :'[primarykey]', :unique
    messages = upgrade.errors.full_messages
    expect(messages).to be_include 'The product_name is not 10 characters.'
    expect(messages).to be_include 'The product_name is not a valid String.'
    expect(messages).to be_include 'The version is not a number.'
    expect(messages).to be_include 'The upgrade is created.'
  end
end
