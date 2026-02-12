class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.string :content
      t.references :sender, polymorphic: true
      t.references :receiver, polymorphic: true

      t.timestamps
    end
  end
end
