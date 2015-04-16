describe CassandraORM::Base do
  it 'should not be nil' do
    expect(CassandraORM::Base.cluster).not_to be_nil
    expect(CassandraORM::Base.keyspace).not_to be_nil
    expect(CassandraORM::Base.session).not_to be_nil
  end

  it 'should be able to heartbeat' do
    expect(CassandraORM.heartbeat).to be true
  end

  it 'should be able to reconnect' do
    10.times do
      fork do
        CassandraORM.reconnect
        exit! CassandraORM.heartbeat
      end
    end
    expect(Process.waitall.map { |_, status| status.exitstatus }).to all be 0
  end
end
