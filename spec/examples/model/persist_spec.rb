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

  context 'create' do
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
      upgrade = Upgrade.find product_name: 'cassandra', version: 1
      expect(upgrade).to be_nil
      upgrade = Upgrade.new product_name: 'cassandra', version: 1,
                            minimal_version: 0, url: 'http://cassandra.apache.org/'
      expect(upgrade.save).to be true
      expect(upgrade.product_name).to eq 'cassandra'
      expect(upgrade.version).to eq 1
      expect(upgrade.minimal_version).to eq 0
      expect(upgrade.url).to eq 'http://cassandra.apache.org/'
      expect(upgrade.changelog).to be_nil
    end

    it 'should be able to detect uniqueness conflict' do
      product = Product.new name: 'cassandra'
      expect(product.save).to be true
      product = Product.new name: 'cassandra'
      expect(product.save).to be false
      expect(product.errors).to match name: :unique

      upgrade = Upgrade.new product_name: 'cassandra', version: 1,
                            minimal_version: 0, url: 'http://cassandra.apache.org/'
      expect(upgrade.save).to be true
      upgrade = Upgrade.new product_name: 'cassandra', version: 1,
                            minimal_version: 0, url: 'http://cassandra.apache.org/'
      expect(upgrade.save).to be false
      expect(upgrade.errors).to match [:product_name, :version] => :unique
    end
  end

  context 'update' do
    let(:product) { Product.new(name: 'cassandra').tap(&:save) }
    let(:upgrade) { Upgrade.new(product_name: 'cassandra', version: 1, minimal_version: 0,
                                url: 'http://cassandra.apache.org', changelog: 'Changelog for 1.0').tap(&:save) }
    it 'should not be able to update product\'s name' do
      expect(product.new?).to be false
      expect { product.name = 'cannot update' }.to raise_error CassandraORM::CannotUpdatePrimaryKey
    end

    it 'should not be able to update version of the upgrade' do
      expect(upgrade.new?).to be false
      expect { upgrade.version = 2 }.to raise_error CassandraORM::CannotUpdatePrimaryKey
    end

    it 'should be able to update url of the upgrade' do
      expect(upgrade.new?).to be false
      expect { upgrade.url = 'http://www.datastax.com/' }.not_to raise_error
    end
  end
end
