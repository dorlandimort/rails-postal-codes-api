class CreatePostalCodes < ActiveRecord::Migration[5.1]
  def change
    create_table :postal_codes do |t|
      t.string :code
      t.string :colony
      t.string :municipality
      t.string :state
    end
    add_index :postal_codes, :code
  end
end
