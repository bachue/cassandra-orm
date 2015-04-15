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
    pids = (1..10).map do
      fork do
        CassandraORM.reconnect
        exit! CassandraORM.heartbeat
      end
    end
    pids.each do |pid|
      _, status = Process.waitpid2 pid
      expect(status.exitstatus).to be 0
    end
  end
end
