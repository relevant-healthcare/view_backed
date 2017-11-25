class CreatePatients < ActiveRecord::Migration
  def change
    create_table :patients do |t|
      t.string :name
      t.date :date_of_birth
      t.references :provider, index: true, foreign_key: true

      t.timestamps
    end
  end
end
