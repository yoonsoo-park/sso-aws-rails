class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :cognito_sub, null: false
      t.string :given_name
      t.string :family_name
      t.datetime :last_sign_in_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :cognito_sub, unique: true
  end
end
