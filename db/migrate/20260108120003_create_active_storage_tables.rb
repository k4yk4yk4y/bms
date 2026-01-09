class CreateActiveStorageTables < ActiveRecord::Migration[8.0]
  def change
    unless table_exists?(:active_storage_blobs)
      create_table :active_storage_blobs do |t|
        t.string :key, null: false
        t.string :filename, null: false
        t.string :content_type
        t.text :metadata
        t.string :service_name, null: false
        t.bigint :byte_size, null: false
        t.string :checksum
        t.datetime :created_at, null: false
      end
    end

    add_index :active_storage_blobs, :key, unique: true unless index_exists?(:active_storage_blobs, :key, unique: true)

    unless table_exists?(:active_storage_attachments)
      create_table :active_storage_attachments do |t|
        t.string :name, null: false
        t.references :record, null: false, polymorphic: true, index: false
        t.references :blob, null: false
        t.datetime :created_at, null: false
      end
    end

    unless index_exists?(:active_storage_attachments,
                         [ :record_type, :record_id, :name, :blob_id ],
                         unique: true,
                         name: "index_active_storage_attachments_uniqueness")
      add_index :active_storage_attachments,
                [ :record_type, :record_id, :name, :blob_id ],
                name: "index_active_storage_attachments_uniqueness",
                unique: true
    end
    add_index :active_storage_attachments, [ :blob_id ] unless index_exists?(:active_storage_attachments, :blob_id)

    unless table_exists?(:active_storage_variant_records)
      create_table :active_storage_variant_records do |t|
        t.belongs_to :blob, null: false, index: false
        t.string :variation_digest, null: false
      end
    end

    unless index_exists?(:active_storage_variant_records,
                         [ :blob_id, :variation_digest ],
                         unique: true,
                         name: "index_active_storage_variant_records_uniqueness")
      add_index :active_storage_variant_records,
                [ :blob_id, :variation_digest ],
                name: "index_active_storage_variant_records_uniqueness",
                unique: true
    end

    unless foreign_key_exists?(:active_storage_attachments, :active_storage_blobs, column: :blob_id)
      add_foreign_key :active_storage_attachments, :active_storage_blobs, column: :blob_id
    end
    unless foreign_key_exists?(:active_storage_variant_records, :active_storage_blobs, column: :blob_id)
      add_foreign_key :active_storage_variant_records, :active_storage_blobs, column: :blob_id
    end
  end
end
