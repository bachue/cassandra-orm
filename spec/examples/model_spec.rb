describe CassandraORM::Model do
  before :each do
    Upgrade = Class.new CassandraORM::Model do
      set_primary_key :product_name, 'version'
      attributes :minimal_version, :url, 'changelog', 'created_at'
    end
  end

  it 'should return all attributes' do
    expect(Upgrade.attributes).to eq %i(product_name version minimal_version url changelog created_at)
  end

  it 'should return the primary key' do
    expect(Upgrade.primary_key).to eq %i(product_name version)
  end

  it 'should be able to read or write primary key and attributes' do
    upgrade = Upgrade.new
    upgrade.product_name = 'cassandra-orm'
    upgrade.version = '1.0'
    upgrade.minimal_version = '0.0'
    upgrade.changelog = 'It can use now!'
    upgrade.url = 'https://github.com/bachue/cassandra-orm.git'
    expect(upgrade.product_name).to eq 'cassandra-orm'
    expect(upgrade.version).to eq '1.0'
    expect(upgrade.minimal_version).to eq '0.0'
    expect(upgrade.changelog).to eq 'It can use now!'
    expect(upgrade.url).to eq 'https://github.com/bachue/cassandra-orm.git'
  end

  it 'should be able to initialize' do
    upgrade = Upgrade.new product_name: 'cassandra-orm', version: '1.0', minimal_version: '0.0',
                          url: 'https://github.com/bachue/cassandra-orm.git', changelog: 'It can use now!'
    expect(upgrade.product_name).to eq 'cassandra-orm'
    expect(upgrade.version).to eq '1.0'
    expect(upgrade.minimal_version).to eq '0.0'
    expect(upgrade.changelog).to eq 'It can use now!'
    expect(upgrade.url).to eq 'https://github.com/bachue/cassandra-orm.git'
  end

  it 'should be able to get all attributes by #attributes' do
    now = Time.now
    upgrade = Upgrade.new product_name: 'cassandra-orm', version: '1.0', minimal_version: '0.0',
                          url: 'https://github.com/bachue/cassandra-orm.git', changelog: 'It can use now!',
                          created_at: now
    expect(upgrade.attributes).to eq product_name: 'cassandra-orm', version: '1.0', minimal_version: '0.0',
                                     url: 'https://github.com/bachue/cassandra-orm.git', changelog: 'It can use now!',
                                     created_at: now
  end
end
