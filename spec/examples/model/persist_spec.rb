describe CassandraORM::Model::Persist do
  before :each do
    Product = Class.new CassandraORM::Model do
      set_primary_key :name
    end
    Upgrade = Class.new CassandraORM::Model do
      set_primary_key :product_name, :version
      attributes :minimal_version, :url, :changelog, :created_at
    end
  end

  it 'should be able to create a product' do
    product = Product.find(name: 'cassandra')
    expect(product).to be_nil
    product = Product.new name: 'cassandra'
    expect(product.save).to be true
    expect(product).not_to be_new
    expect(product.errors).to be_empty
    product = Product.find(name: 'cassandra')
    expect(product).not_to be_nil
    expect(product).not_to be_new
    expect(product.name).to eq 'cassandra'
  end

  it 'should be able to create an upgrade' do
    upgrade = Upgrade.find product_name: 'cassandra', version: Cassandra::Tuple.new(1, 0)
    expect(upgrade).to be_nil
    upgrade = Upgrade.new product_name: 'cassandra', version: Cassandra::Tuple.new(1, 0),
                          minimal_version: Cassandra::Tuple.new(0, 0), url: 'http://cassandra.apache.org/'
    expect(upgrade.save(reload: true)).to be true
    expect(upgrade.product_name).to eq 'cassandra'
    expect(upgrade.version).to eq Cassandra::Tuple.new(1, 0)
    expect(upgrade.minimal_version).to eq Cassandra::Tuple.new(0, 0)
    expect(upgrade.url).to eq 'http://cassandra.apache.org/'
    expect(upgrade.changelog).to be_nil
  end

  it 'should be able to detect uniqueness conflict' do
    product = Product.new name: 'cassandra'
    expect(product.save).to be true
    product = Product.new name: 'cassandra'
    expect(product.save).to be false
    expect(product.errors).to match name: :unique

    upgrade = Upgrade.new product_name: 'cassandra', version: Cassandra::Tuple.new(1, 0),
                          minimal_version: Cassandra::Tuple.new(0, 0), url: 'http://cassandra.apache.org/'
    expect(upgrade.save).to be true
    upgrade = Upgrade.new product_name: 'cassandra', version: Cassandra::Tuple.new(1, 0),
                          minimal_version: Cassandra::Tuple.new(0, 0), url: 'http://cassandra.apache.org/'
    expect(upgrade.save).to be false
    expect(upgrade.errors).to match [:product_name, :version] => :unique
  end
end
