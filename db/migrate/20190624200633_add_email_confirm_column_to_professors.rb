class AddEmailConfirmColumnToProfessors < ActiveRecord::Migration[5.2]
  def change
    add_column :professors, :email_confirmed, :boolean, :default => false
    add_column :professors, :confirm_token, :string
  end
end
