describe CassandraORM::Model do
  before :each do
    Product = Class.new CassandraORM::Model do
      set_primary_key :name
    end
    Upgrade = Class.new CassandraORM::Model do
      set_primary_key :product_name, 'version'
      attributes :minimal_version, :url, 'changelog'
    end
  end

  it 'should return all attributes' do
    expect(Product.attributes).to eq %i(name)
    expect(Upgrade.attributes).to eq %i(product_name version minimal_version url changelog)
  end

  it 'should return the primary key' do
    expect(Product.primary_key).to eq %i(name)
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
                          url: 'https://github.com/bachue/cassandra-orm.git', changelog: 'It can use now!'
    expect(upgrade.attributes).to eq product_name: 'cassandra-orm', version: '1.0', minimal_version: '0.0',
                                     url: 'https://github.com/bachue/cassandra-orm.git', changelog: 'It can use now!'
  end

  it 'should be able to get all primary key values by #primary_key_hash' do
    upgrade = Upgrade.new product_name: 'cassandra-orm', version: '1.0', minimal_version: '0.0',
                          url: 'https://github.com/bachue/cassandra-orm.git', changelog: 'It can use now!'
    expect(upgrade.primary_key_hash).to eq product_name: 'cassandra-orm', version: '1.0'
  end

  it 'should be able to calculate table name' do
    expect(Product.table_name).to eq 'products'
    expect(Upgrade.table_name).to eq 'upgrades'
  end

  it 'should be able to compare between models' do
    product1 = Product.new name: 'cassandra'
    product2 = Product.new name: 'cassandra'
    product3 = Product.new name: 'cassandra-orm'
    expect(product1).to eq product2
    expect(product2).to eq product1
    expect(product1).not_to eq product3
    expect(product3).not_to eq product1
  end

  it 'should be able to reload the model' do
    upgrade1 = Upgrade.new product_name: 'cassandra-orm', version: 1, minimal_version: 0,
                           url: 'https://github.com/bachue/cassandra-orm.git', changelog: 'It can use now!'
    expect(upgrade1.save).to be true
    upgrade2 = Upgrade.new product_name: 'cassandra-orm', version: 1, minimal_version: 0,
                           url: 'https://github.com/bachue/cassandra-orm.git', changelog: 'It\'s the best orm!'
    expect(upgrade2.reload).to be upgrade2
    expect(upgrade2.new?).to be false
    expect(upgrade2.attributes).to eq upgrade1.attributes
  end

  it 'should not be able to reload if the model is deleted' do
    upgrade1 = Upgrade.new product_name: 'cassandra-orm', version: 1, minimal_version: 0,
                           url: 'https://github.com/bachue/cassandra-orm.git', changelog: 'It can use now!'
    expect(upgrade1.save).to be true
    upgrade2 = upgrade1.dup
    expect(upgrade1.destroy).to be true
    expect(upgrade2.reload).to be false
    expect(upgrade2.new?).to be true
    expect(upgrade2.errors).to be_empty
  end
end
