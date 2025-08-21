class BackfillAccountsFieldsCount < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!  # evita lock longo se a tabela for grande

  def up
    say_with_time "Backfilling accounts.fields_count" do
      # zera tudo
      execute "UPDATE accounts SET fields_count = 0"

      # conta fields por account_id
      rows = execute <<~SQL
        SELECT account_id, COUNT(*) AS cnt
        FROM fields
        WHERE account_id IS NOT NULL
        GROUP BY account_id
      SQL

      rows.each do |r|
        execute <<~SQL
          UPDATE accounts
          SET fields_count = #{r['cnt'].to_i}
          WHERE id = #{r['account_id'].to_i}
        SQL
      end
    end
  end

  def down
    # não reverte contagens (não é crítico)
  end
end
