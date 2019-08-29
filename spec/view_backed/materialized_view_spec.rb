require 'rails_helper'

RSpec.describe ViewBacked::MaterializedView do
  let(:materialized_view) do
    ViewBacked::MaterializedView.new(
      name: view_name,
      sql: view_sql,
      with_data: with_data
    )
  end

  let(:with_data) { false }
  let(:view_name) { 'test_view' }
  let(:view_sql) { 'select 1 AS id' }

  after do
    ActiveRecord::Base.connection.execute "DROP MATERIALIZED VIEW IF EXISTS #{view_name}"
  end

  describe '#wait_until_populated' do
    it 'calls #break_db_record_cache! and waits until populated? is true' do
      allow(materialized_view).to receive(:populated?).and_return(false, true)
      expect(materialized_view).to receive(:break_db_record_cache!)
      expect(materialized_view).to receive(:populated?).twice
      materialized_view.wait_until_populated
    end

    context 'when max_refresh_wait_time is set' do
      around do |example|
        previous_max_refresh_wait_time = ViewBacked.options[:max_refresh_wait_time]
        ViewBacked.options[:max_refresh_wait_time] = max_refresh_wait_time
        example.run
        ViewBacked.options[:max_refresh_wait_time] = previous_max_refresh_wait_time
      end

      before { allow(materialized_view).to receive(:populated?).and_return(false, true) }

      context 'and exceeded' do
        let(:max_refresh_wait_time) { 0.5 }

        it 'raises max refresh wait time exceeded error' do
          expect { materialized_view.wait_until_populated }.to raise_error(
            ViewBacked::MaxRefreshWaitTimeExceededError
          )
        end
      end

      context 'and not exceeded' do
        let(:max_refresh_wait_time) { 3 }

        it 'does not raise' do
          expect { materialized_view.wait_until_populated }.not_to raise_error
        end
      end
    end
  end

  describe '#populated?' do
    context 'when populated' do
      let(:with_data) { true }
      before do
        materialized_view.ensure_current!
      end

      it 'is truthy' do
        expect(materialized_view).to be_populated
      end
    end

    context 'when not populated' do
      before do
        materialized_view.ensure_current!
      end

      it 'is falsey' do
        expect(materialized_view).not_to be_populated
      end
    end
  end

  describe '#break_db_record_cache' do
    before do
      materialized_view.ensure_current!
    end

    it 'breaks the cache' do
      expect(materialized_view).not_to be_populated

      ViewBacked::MaterializedViewRefresh.new(
        connection: ActiveRecord::Base.connection,
        view_name: view_name
      ).save!

      expect { materialized_view.break_db_record_cache! }
            .to change { materialized_view.populated? }
            .from(false)
            .to(true)
    end
  end
end
