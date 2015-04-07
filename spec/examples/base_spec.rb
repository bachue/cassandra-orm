describe CassandraORM::Base do
  it 'should not be nil' do
    expect(CassandraORM::Base.cluster).not_to be_nil
    expect(CassandraORM::Base.keyspace).not_to be_nil
    expect(CassandraORM::Base.session).not_to be_nil
  end
end
