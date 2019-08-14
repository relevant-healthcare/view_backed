require 'rails_helper'

RSpec.describe ViewBacked do
  context 'not materialized' do
    class ViewBackedModel < ActiveRecord::Base
      include ViewBacked

      view do |v|
        v.string :id, "provider_id || '-' || date_of_birth"
        v.integer :provider_id, 'provider_id'
        v.date :date_of_birth
        v.integer :patient_count, 'COUNT(*)'
        v.decimal :average_risk_score, 'AVG(risk_score)'
        v.boolean :risk_score_above_2, 'AVG(risk_score) > 2'
        v.column :sum_risk_score, :decimal, 'SUM(risk_score)'

        v.from Patient.group(:provider_id, :date_of_birth)
      end

      belongs_to :provider
    end

    let(:view_backed_instance) do
      ViewBackedModel.find_by(date_of_birth: Date.new(1991, 10, 31))
    end

    let!(:patient_alpha) do
      Fabricate(
        :patient,
        provider: provider_alpha,
        date_of_birth: Date.new(1991, 10, 31),
        risk_score: 2
      )
    end

    let!(:patient_alpha_two) do
      Fabricate(
        :patient,
        provider: provider_alpha,
        date_of_birth: Date.new(1991, 10, 31),
        risk_score: 3
      )
    end

    let(:provider_alpha) { Fabricate(:provider, name: 'Alpha') }

    let!(:patient_beta) do
      Fabricate(
        :patient,
        provider: provider_beta,
        date_of_birth: Date.new(1981, 10, 31)
      )
    end

    let(:provider_beta) { Fabricate(:provider, name: 'Beta') }

    describe '.view' do
      it 'configures string columns' do

        expect(view_backed_instance.id).to eq "#{provider_alpha.id}-1991-10-31"
      end

      it 'configures integer columns' do
        expect(view_backed_instance.provider_id).to eq provider_alpha.id
      end

      it 'configures date columns and infers sql selection expressions' do
        expect(view_backed_instance.date_of_birth).to eq Date.new(1991, 10, 31)
      end

      it 'configures decimal column' do
        expect(view_backed_instance.average_risk_score).to eq 2.5
      end

      it 'configures boolean column' do
        expect(view_backed_instance.risk_score_above_2).to eq true
        expect(view_backed_instance.risk_score_above_2?).to eq true
      end

      it 'configures a column defined with #column syntax' do
        expect(view_backed_instance.sum_risk_score).to eq 5
      end

      it 'specifies default_scope of model' do
        expect(ViewBackedModel.pluck(:id)).to contain_exactly(
          "#{provider_alpha.id}-1991-10-31",
          "#{provider_beta.id}-1981-10-31"
        )
      end
    end

    it 'plays nice with associations' do
      expect(view_backed_instance.provider).to eq provider_alpha
      expect(
        ViewBackedModel.joins(:provider)
                       .where(providers: { name: 'Alpha' })
      ).to contain_exactly view_backed_instance
    end
  end

  context 'materialized' do

    let(:materialized_view_back_model) do
      Class.new(ActiveRecord::Base) do |c|
        c.include ViewBacked

        c.materialized true

        c.view do |v|
          v.integer :id
          v.integer :provider_id, 'provider_id', index: true
          v.date :date_of_birth

          v.from Patient.all
        end
      end
    end

    let(:view_class_name) { 'TestView' }
    let(:view_table_name) { view_class_name.tableize }

    before { allow(materialized_view_back_model).to receive(:name) { view_class_name } }
    before { allow(materialized_view_back_model).to receive(:table_name) { view_table_name } }

    after do
      ActiveRecord::Base.connection.execute "DROP MATERIALIZED VIEW IF EXISTS #{view_table_name}"
    end

    describe '.view' do
      context 'when a view does not exist in the database' do
        before do
          materialized_view_back_model.all # trigger view creation
        end

        let(:persisted_view) do
          ActiveRecord::Base.connection.execute(
            "SELECT * FROM pg_matviews WHERE matviewname = '#{view_table_name}'"
          ).first
        end

        it 'creates the view' do
          expect(persisted_view).to be_present
        end
      end

      context 'when there is an outdated view in the database' do
        before do
          ActiveRecord::Base.connection.execute <<~SQL.squish
            DROP MATERIALIZED VIEW IF EXISTS #{view_table_name};
            CREATE MATERIALIZED VIEW #{view_table_name} AS (SELECT 'out-of-date' AS date_of_birth);
          SQL
          Fabricate(:patient, date_of_birth: Date.new(1991, 10, 1))
        end

        it 'recreates the view' do
          expect(materialized_view_back_model.first.date_of_birth).to eq Date.new(1991, 10, 1)
        end
      end

      context 'when there is an up-to-date view in the database' do
        before do
          ActiveRecord::Base.connection.execute <<~SQL.squish
            DROP MATERIALIZED VIEW IF EXISTS #{view_table_name};
            CREATE MATERIALIZED VIEW #{view_table_name} AS (#{materialized_view_back_model.view_definition.to_sql});
          SQL

          Fabricate(:patient, date_of_birth: Date.new(1991, 10, 1))
        end

        it 'does not recreate the view' do
          expect(materialized_view_back_model.count).to eq 0
        end
      end
    end

    describe '.refresh!' do
      before do
        materialized_view_back_model.all # trigger view creation
        Fabricate(:patient, date_of_birth: Date.new(1991, 11, 30))
      end

      it 'refreshes' do
        expect(materialized_view_back_model.count).to eq 0
        materialized_view_back_model.refresh!
        expect(materialized_view_back_model.count).to eq 1
      end
    end
  end
end
