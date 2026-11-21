namespace :backfills do
  namespace :run do
    # TODO: delete once it has run in production, before the project tables are dropped.
    desc "Delete leftover custom project rows so customers and shops can be deleted"
    task delete_custom_projects: :environment do
      tables = [
        "payments",
        "invoice_line_items",
        "invoices",
        "project_materials",
        "material_orders",
        "project_assignments",
        "design_renderings",
        "design_rounds",
        "project_references",
        "projects"
      ]
      record_types = ["Project", "ProjectReference", "DesignRendering", "MaterialOrder"]

      ActiveRecord::Base.transaction do
        attachments = ActiveStorage::Attachment.where(record_type: record_types)
        blob_ids = attachments.pluck(:blob_id)
        puts "#{attachments.delete_all} attachments deleted"
        ActiveStorage::Blob.where(id: blob_ids).find_each(&:purge_later)

        puts "#{Event.where(owner_type: "Project").delete_all} events deleted"
        puts "#{Note.where(noteable_type: "Project").delete_all} notes deleted"

        tables.each do |table|
          deleted = ActiveRecord::Base.connection.delete(Arel::DeleteManager.new.from(Arel::Table.new(table)))
          puts "#{deleted} #{table} deleted"
        end
      end
    end
  end
end
