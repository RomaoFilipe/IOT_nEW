class AddExpenseCategoryToFinancials < ActiveRecord::Migration[7.2]
  def change
    add_column :financials, :expense_category, :string
  end
end
