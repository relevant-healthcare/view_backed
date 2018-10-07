class CreatePatients < ActiveRecord::Migration[5.2]
  def change
    create_table :patients do |t|
      t.references :provider
      t.date :date_of_birth
      t.decimal :risk_score
    end
  end
end
