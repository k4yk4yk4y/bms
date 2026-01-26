class CreateHeatmapComments < ActiveRecord::Migration[8.0]
  def change
    if table_exists?(:heatmap_comments)
      add_column :heatmap_comments, :date, :date unless column_exists?(:heatmap_comments, :date)
      add_column :heatmap_comments, :body, :text unless column_exists?(:heatmap_comments, :body)
      add_reference :heatmap_comments, :user, foreign_key: true unless column_exists?(:heatmap_comments, :user_id)

      if column_exists?(:heatmap_comments, :date) && !index_exists?(:heatmap_comments, :date)
        add_index :heatmap_comments, :date
      end

      reversible do |dir|
        dir.up do
          if column_exists?(:heatmap_comments, :start_date) && column_exists?(:heatmap_comments, :date)
            execute <<~SQL.squish
              UPDATE heatmap_comments
              SET date = start_date
              WHERE date IS NULL AND start_date IS NOT NULL
            SQL
          end

          if column_exists?(:heatmap_comments, :text) && column_exists?(:heatmap_comments, :body)
            execute <<~SQL.squish
              UPDATE heatmap_comments
              SET body = text
              WHERE body IS NULL AND text IS NOT NULL
            SQL
          end
        end
      end
    else
      create_table :heatmap_comments do |t|
        t.date :date, null: false
        t.text :body, null: false
        t.references :user, null: false, foreign_key: true

        t.timestamps
      end

      add_index :heatmap_comments, :date
    end
  end
end
