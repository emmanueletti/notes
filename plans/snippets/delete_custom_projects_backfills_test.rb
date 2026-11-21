require "test_helper"
require "rake"

class BackfillsTasksTest < ActiveSupport::TestCase
  setup do
    Rake::Task.define_task(:environment)
    Rake.application.rake_require("tasks/backfills", [Rails.root.join("lib").to_s])
  end

  test "backfills:run:delete_custom_projects lets a customer with an invoiced project be deleted" do
    customer = create(:customer)
    project_id = insert_project(customer)
    insert_row("invoices", project_id: project_id, currency: "usd", status: "draft")
    project_note = customer.notes.create!(content: "x", repair_shop: customer.repair_shop, team_member: create(:team_member, repair_shop: customer.repair_shop))
    project_note.update_columns(noteable_type: "Project", noteable_id: project_id)

    capture_io { run_task("backfills:run:delete_custom_projects") }

    assert_equal 0, ActiveRecord::Base.connection.select_value("SELECT count(*) FROM projects")
    assert_equal 0, ActiveRecord::Base.connection.select_value("SELECT count(*) FROM invoices")
    assert_not Note.exists?(project_note.id)
    customer.destroy!
    assert_not Customer.exists?(customer.id)
  end

  private

  def insert_project(customer)
    insert_row(
      "projects",
      customer_id: customer.id,
      repair_shop_id: customer.repair_shop_id,
      current_stage: "intake",
      min_budget_amount: 0,
      name: "Ring",
      status: "active",
      target_date: Date.current
    )
  end

  def insert_row(table, **attributes)
    now = Time.current
    ActiveRecord::Base.connection.insert(
      Arel::InsertManager.new.tap do |manager|
        arel_table = Arel::Table.new(table)
        manager.insert(attributes.merge(created_at: now, updated_at: now).map { |column, value| [arel_table[column], value] })
      end
    )
  end

  def run_task(name)
    task = Rake::Task[name]
    task.reenable
    task.invoke
  end
end
