require 'rails_helper'

RSpec.describe ViewBacked do
  class ViewBackedModel < ActiveRecord::Base
    include ViewBacked

    view do |v|
      v.string :id, "provider_id || '-' || date_of_birth"
      v.integer :provider_id, 'provider_id'
      v.date :date_of_birth
      v.integer :patient_count, 'COUNT(*)'
      v.decimal :average_risk_score, 'AVG(risk_score)'
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
