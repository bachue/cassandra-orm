describe CassandraORM::Model::Persist do
  before :each do
    Product = Class.new CassandraORM::Model do
      set_primary_key :name
    end
    Upgrade = Class.new CassandraORM::Model do
      set_primary_key :product_name, :version
      attributes :minimal_version, :url, :changelog
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
      expect(product.save(exclusive: true)).to be false
      expect(product.new?).to be true
      expect(product.errors).to match '[failed]': :unique

      upgrade = Upgrade.new product_name: 'cassandra', version: 1,
                            minimal_version: 0, url: 'http://cassandra.apache.org/'
      expect(upgrade.save(exclusive: true)).to be true
      expect(upgrade.new?).to be false
      upgrade = Upgrade.new product_name: 'cassandra', version: 1,
                            minimal_version: 0, url: 'http://cassandra.apache.org/'
      expect(upgrade.save(exclusive: true)).to be false
      expect(upgrade.new?).to be true
      expect(upgrade.errors).to match '[failed]': :unique
    end

    it 'should raise error when save failed' do
      product = Product.new name: 'cassandra'
      expect(product.save!).to be true
      expect(product.new?).to be false
      product = Product.new name: 'cassandra'
      expect { product.save!(exclusive: true) }.to raise_error CassandraORM::SaveFailure
      expect(product.new?).to be true
      expect(product.errors).to match '[failed]': :unique

      upgrade = Upgrade.new product_name: 'cassandra', version: 1,
                            minimal_version: 0, url: 'http://cassandra.apache.org/'
      expect(upgrade.save!(exclusive: true)).to be true
      expect(upgrade.new?).to be false
      upgrade = Upgrade.new product_name: 'cassandra', version: 1,
                            minimal_version: 0, url: 'http://cassandra.apache.org/'
      expect { upgrade.save!(exclusive: true) }.to raise_error CassandraORM::SaveFailure
      expect(upgrade.new?).to be true
      expect(upgrade.errors).to match '[failed]': :unique
    end

    it 'should clear errors when save a model successfully' do
      product1 = Product.new name: 'cassandra'
      expect(product1.save(exclusive: true)).to be true
      product2 = Product.new name: 'cassandra'
      expect(product2.save(exclusive: true)).to be false
      expect(product2.errors).to match '[failed]': :unique
      expect(product1.destroy).to be true
      expect(product2.save(exclusive: true)).to be true
      expect(product2.errors).to be_empty
    end
  end

  context 'update' do
    let(:product) { Product.new(name: 'cassandra').tap(&:save!) }
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

    it 'should not add :exclusive option when try to update' do
      upgrade.url = 'http://www.datastax.com/'
      expect(upgrade.save(exclusive: true)).to be false
      expect(upgrade.errors).to match '[failed]': :unique
      expect(upgrade.save).to be true
    end

    it 'should raise error when failed to save' do
      upgrade.url = 'http://www.datastax.com/'
      expect { upgrade.save!(exclusive: true) }.to raise_error CassandraORM::SaveFailure
      expect(upgrade.errors).to match '[failed]': :unique
      expect(upgrade.save!).to be true
    end

    it 'should still be able to update unexisted model' do
      upgrade2 = upgrade.dup
      expect(upgrade2.destroy).to be true
      upgrade.url = 'http://www.datastax.com/'
      expect(upgrade.save).to be true
      upgrade = Upgrade.find product_name: 'cassandra', version: 1
      expect(upgrade.url).to eq 'http://www.datastax.com/'
    end

    it 'should not be able to update unexisted model if condition is applied' do
      upgrade2 = upgrade.dup
      expect(upgrade2.destroy).to be true
      upgrade.url = 'http://www.datastax.com/'
      expect(upgrade.save(if: {url: 'http://cassandra.apache.org'})).to be false
      expect(upgrade.errors).to match '[failed]': :conditions
      expect(Upgrade.find(product_name: 'cassandra', version: 1)).to be_nil
    end
  end

  context 'validation' do
    before :each do
      Upgrade.class_exec do
        def before_save
          append_error! :minimal_version, :presence unless @minimal_version
          append_error! :minimal_version, :smaller unless @minimal_version < @version
        end

        def before_update
          append_error! :url, :presence unless @url
          append_error! :url, :format unless @url.start_with?('http://')
        end
      end
    end

    it 'should be able to validate' do
      upgrade = Upgrade.new product_name: 'cassandra', version: 1
      expect(upgrade.save).to be false
      expect(upgrade.errors).to eq minimal_version: :presence
      upgrade.minimal_version = 1
      expect(upgrade.save).to be false
      expect(upgrade.errors).to eq minimal_version: :smaller
      upgrade.minimal_version = 0
      expect(upgrade.save).to be true
      expect(upgrade.errors).to be_empty
      expect(upgrade.save).to be false
      expect(upgrade.errors).to eq url: :presence
      upgrade.url = 'https://cassandra.apache.org'
      expect(upgrade.save).to be false
      expect(upgrade.errors).to eq url: :format
      upgrade.url = 'http://cassandra.apache.org'
      expect(upgrade.save).to be true
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

    it 'should no be able to delete a deleted object if condition is applied' do
      upgrade2 = upgrade.dup
      expect(upgrade.destroy).to be true
      expect(upgrade2.destroy(if: {minimal_version: 0})).to be false
      expect(upgrade2.new?).to be false
      expect(upgrade2.errors).to match '[failed]': :conditions
    end

    it 'should raise error when failed to delete an object' do
      upgrade2 = upgrade.dup
      expect(upgrade.destroy!).to be true
      expect { upgrade2.destroy!(if: {minimal_version: 0}) }.to raise_error CassandraORM::DestroyFailure
      expect(upgrade2.new?).to be false
      expect(upgrade2.errors).to match '[failed]': :conditions
    end

    it 'should clear errors when delete a model successfully' do
      product = Product.new name: 'cassandra'
      expect(product.save(exclusive: true)).to be true
      product = Product.new name: 'cassandra'
      expect(product.save(exclusive: true)).to be false
      expect(product.errors).to match '[failed]': :unique
      expect(product.destroy).to be true
      expect(product.new?).to be true
      expect(product.errors).to be_empty
    end
  end
end
