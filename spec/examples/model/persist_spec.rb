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
      expect(product.new?).to be false
      expect(product).not_to be_new
      expect(product.errors).to be_empty
      product = Product.find(name: 'cassandra')
      expect(product.new?).to be false
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
      expect(upgrade.new?).to be false
      expect(upgrade.product_name).to eq 'cassandra'
      expect(upgrade.version).to eq 1
      expect(upgrade.minimal_version).to eq 0
      expect(upgrade.url).to eq 'http://cassandra.apache.org/'
      expect(upgrade.changelog).to be_nil
    end

    it 'should be able to detect uniqueness conflict' do
      product = Product.new name: 'cassandra'
      expect(product.save).to be true
      expect(product.new?).to be false
      product = Product.new name: 'cassandra'
      expect(product.save).to be false
      expect(product.new?).to be true
      expect(product.errors).to match name: :unique

      upgrade = Upgrade.new product_name: 'cassandra', version: 1,
                            minimal_version: 0, url: 'http://cassandra.apache.org/'
      expect(upgrade.save).to be true
      expect(upgrade.new?).to be false
      upgrade = Upgrade.new product_name: 'cassandra', version: 1,
                            minimal_version: 0, url: 'http://cassandra.apache.org/'
      expect(upgrade.save).to be false
      expect(upgrade.new?).to be true
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

    it 'should be able to save the new url' do
      upgrade.url = 'http://www.datastax.com/'
      expect(upgrade.save).to be true
      expect(upgrade.new?).to be false
      expect(upgrade.url).to eq 'http://www.datastax.com/'
      upgrade = Upgrade.find product_name: 'cassandra', version: 1
      expect(upgrade.url).to eq 'http://www.datastax.com/'
    end
  end

  context 'destroy' do
    let(:upgrade) { Upgrade.new(product_name: 'cassandra', version: 1, minimal_version: 0,
                                url: 'http://cassandra.apache.org', changelog: 'Changelog for 1.0').tap(&:save) }

    it 'should be able to destroy the upgrade' do
      expect(upgrade.new?).to be false
      expect(upgrade.destroy).to be true
      expect(upgrade.new?).to be true
      expect(Upgrade.find(product_name: 'cassandra', version: 1)).to be_nil
    end

    it 'should be able to destroy new object even no effect' do
      product = Product.new name: 'cassandra'
      expect(product.destroy).to be true
    end

    it 'should be able to delete one object twice even no effect' do
      expect(upgrade.destroy).to be true
      expect(upgrade.destroy).to be true
    end

    it 'should still be able to delete a deleted object' do
      upgrade2 = upgrade.dup
      expect(upgrade.destroy).to be true
      expect(upgrade2.destroy).to be true
    end
  end
end
