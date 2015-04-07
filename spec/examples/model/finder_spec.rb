describe CassandraORM::Model::Finder do
  before :each do
    Product = Class.new CassandraORM::Model do
      set_primary_key :name
    end
    Upgrade = Class.new CassandraORM::Model do
      set_primary_key :product_name, :version
      attributes :minimal_version, :url, :changelog, :created_at
    end
    Product.session.execute 'INSERT INTO products(name) VALUES(\'cassandra\')'
    Product.session.execute 'INSERT INTO products(name) VALUES(\'orm\')'
    Product.session.execute 'INSERT INTO products(name) VALUES(\'ruby\')'
    Upgrade.session.execute <<-CQL
      INSERT INTO upgrades(product_name, version, minimal_version, url, changelog, created_at)
      VALUES('cassandra', (2, 0), (1, 0), 'http://cassandra.apache.org/', 'changes for 2.0', dateof(NOW()))
    CQL
    Upgrade.session.execute <<-CQL
      INSERT INTO upgrades(product_name, version, minimal_version, url, changelog, created_at)
      VALUES('cassandra', (3, 0), (2, 0), 'http://cassandra.apache.org/', 'changes for 3.0', dateof(NOW()))
    CQL
    Upgrade.session.execute <<-CQL
      INSERT INTO upgrades(product_name, version, minimal_version, url, changelog, created_at)
      VALUES('cassandra', (3, 1), (2, 0), 'http://cassandra.apache.org/', 'changes for 3.1', dateof(NOW()))
    CQL
  end

  it 'should list all products' do
    products = Product.find_all
    expect(products.size).to be 3
    products.each do |product|
      expect(product).to be_a Product
      expect(product).not_to be_new
      expect(%w(cassandra orm ruby)).to be_include product.name
    end
  end

  it 'should be find product by name' do
    product = Product.find name: 'orm'
    expect(product).to be_a Product
    expect(product.name).to eq 'orm'

    product = Product.find name: 'rails'
    expect(product).to be_nil
  end

  it 'should find all cassandra versions' do
    upgrades = Upgrade.find_all product_name: 'cassandra'
    all_versions = {
      [2, 0] => Cassandra::Tuple.new(1,0),
      [3, 0] => Cassandra::Tuple.new(2,0),
      [3, 1] => Cassandra::Tuple.new(2,0)
    }
    expect(upgrades.size).to be 3
    upgrades.each do |upgrade|
      expect(upgrade).to be_a Upgrade
      expect(upgrade).not_to be_new
      expect(upgrade.product_name).to eq 'cassandra'
      expect(upgrade.url).to eq 'http://cassandra.apache.org/'
      expect(upgrade.changelog).to match(/^changes for \d\.\d$/)
      expect(all_versions.keys).to be_include upgrade.version.to_a
      expect(upgrade.minimal_version).to eq all_versions[upgrade.version.to_a]
    end

    upgrades = Upgrade.find_all product_name: 'orm'
    expect(upgrades).to be_empty
  end

  it 'should find single cassandra version' do
    upgrade = Upgrade.find product_name: 'cassandra', version: Cassandra::Tuple.new(3, 1)
    expect(upgrade).to be_a Upgrade
    expect(upgrade).not_to be_new
    expect(upgrade.product_name).to eq 'cassandra'
    expect(upgrade.version).to eq Cassandra::Tuple.new(3, 1)
    expect(upgrade.minimal_version).to eq Cassandra::Tuple.new(2, 0)
    expect(upgrade.url).to eq 'http://cassandra.apache.org/'
    expect(upgrade.changelog).to eq 'changes for 3.1'
  end

  it 'should raise if any invalid key exists' do
    expect { Upgrade.find product_name: 'cassandra', not_exist: true }.to raise_error CassandraORM::InvalidAttributeError
  end

  it 'should not search by non-index key' do
    expect { Upgrade.find product_name: 'cassandra', minimal_version: Cassandra::Tuple.new(2, 0) }.to raise_error Cassandra::Errors::InvalidError
  end
end
