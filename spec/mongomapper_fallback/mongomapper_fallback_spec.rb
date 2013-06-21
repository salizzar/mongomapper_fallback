require 'spec_helper'

describe MongomapperFallback do
  subject do
    class Example
      include MongomapperFallback

      def execute
        replicaset_safe_run!(Logger.new(StringIO.new)) { perform_a_operation }
      end

      def perform_a_operation ; end
    end

    Example.new
  end

  let(:connection) { double('MongoMapper database connection') }

  before :each do
    MongoMapper.stub(connection: connection)
  end

  it 'raises error when it is not related to a MongoDB connection error' do
    error = Exception.new 'an error'
    subject.should_receive(:perform_a_operation).and_raise(error)

    expect { subject.execute }.to raise_error(error)
  end

  describe 'detecting MongoDB connection errors' do
    describe 'detecting Mongo::ConnectionFailure error' do
      it 'refreshs connection' do
        subject.should_receive(:perform_a_operation).and_raise(Mongo::ConnectionFailure)
        connection.should_receive(:hard_refresh!)
        connection.should_not_receive(:reconnect)
        subject.should_receive(:perform_a_operation).and_return(true)

        expect { subject.execute }.to_not raise_error
      end
    end

    describe 'detecting Mongo::OperationFailure error' do
      it 'reconnects to database server' do
        subject.should_receive(:perform_a_operation).and_raise(Mongo::OperationFailure)
        connection.should_receive(:reconnect)
        connection.should_not_receive(:hard_refresh!)
        subject.should_receive(:perform_a_operation).and_return(true)

        expect { subject.execute }.to_not raise_error
      end
    end

    describe 'retrying if attempts raises an error' do
      it 'raises if retry limit is reached' do
        subject.stub(:perform_a_operation).and_raise(Mongo::ConnectionFailure)

        connection.should_receive(:hard_refresh!).exactly(5).times.and_raise(Mongo::ConnectionFailure)

        expect { subject.execute }.to raise_error(Mongo::ConnectionFailure)
      end

      it 'performs a reconnection if hard refresh raises a operation failure' do
        subject.should_receive(:perform_a_operation).and_raise(Mongo::ConnectionFailure)
        connection.should_receive(:hard_refresh!).and_raise(Mongo::OperationFailure)
        connection.should_receive(:reconnect).and_return(true)
        subject.should_receive(:perform_a_operation).and_return(true)

        expect { subject.execute }.to_not raise_error
      end

      it 'performs a hard refresh if reconnection raises a connection failure' do
        subject.should_receive(:perform_a_operation).and_raise(Mongo::OperationFailure)
        connection.should_receive(:reconnect).and_raise(Mongo::ConnectionFailure)
        connection.should_receive(:hard_refresh!).and_return(true)
        subject.should_receive(:perform_a_operation).and_return(true)

        expect { subject.execute }.to_not raise_error
      end
    end
  end

  describe 'custom configuration' do
    before :each do
      subject.class_eval do
        def execute
          replicaset_safe_run!(Logger.new(StringIO.new), sig_quit: true, retry_limit: 10) { perform_a_operation }
        end
      end
    end

    it 'sends a SIGQUIT if flag is setted' do
      ppid = 1234
      Process.should_receive(:ppid).and_return(ppid)
      Process.should_receive(:kill).with('QUIT', ppid)

      subject.should_receive(:perform_a_operation).and_raise(Mongo::OperationFailure)
      connection.should_receive(:reconnect)
      subject.should_receive(:perform_a_operation).and_return(true)

      expect { subject.execute }.to_not raise_error
    end

    it 'retries based on informed value when informed' do
      subject.should_receive(:perform_a_operation).and_raise(Mongo::ConnectionFailure)
      connection.should_receive(:hard_refresh!).exactly(10).times.and_raise(Mongo::ConnectionFailure)

      expect { subject.execute }.to raise_error(Mongo::ConnectionFailure)
    end
  end
end

