class CreateViews < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      CREATE VIEW vw_user_patent_summary AS
      SELECT
        u.id AS user_id,
        u.name AS user_name,
        COUNT(*) FILTER (WHERE p.current_status IN ('filed','published')) AS cnt_active_filings,
        COUNT(*) FILTER (WHERE p.current_status = 'granted') AS cnt_granted,
        COUNT(*) FILTER (WHERE p.current_status = 'rejected') AS cnt_rejected,
        COUNT(*) AS cnt_total
      FROM users u
      LEFT JOIN user_patents up ON up.user_id = u.id
      LEFT JOIN patents p ON p.id = up.patent_id
      GROUP BY u.id;
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW IF EXISTS vw_user_patent_summary;
    SQL
  end
end