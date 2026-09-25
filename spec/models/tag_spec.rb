# spec/models/tag_spec.rb
require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should have_many(:answer_tag_appointments).dependent(:destroy) }
    it { should have_many(:answers).through(:answer_tag_appointments) }
    it { should have_many(:article_tag_appointments).dependent(:destroy) }
    it { should have_many(:articles).through(:article_tag_appointments) }
    it { should have_many(:article_group_tag_appointments).dependent(:destroy) }
    it { should have_many(:article_groups).through(:article_group_tag_appointments) }
    it { should have_many(:branch_tag_appointments).dependent(:destroy) }
    it { should have_many(:branches).through(:branch_tag_appointments) }
    it { should have_many(:brand_tag_appointments).dependent(:destroy) }
    it { should have_many(:brands).through(:brand_tag_appointments) }
    it { should have_many(:company_tag_appointments).dependent(:destroy) }
    it { should have_many(:companies).through(:company_tag_appointments) }
    it { should have_many(:customer_tag_appointments).dependent(:destroy) }
    it { should have_many(:customers).through(:customer_tag_appointments) }
    it { should have_many(:customer_group_tag_appointments).dependent(:destroy) }
    it { should have_many(:customer_groups).through(:customer_group_tag_appointments) }
    it { should have_many(:department_tag_appointments).dependent(:destroy) }
    it { should have_many(:departments).through(:department_tag_appointments) }
    it { should have_many(:document_tag_appointments).dependent(:destroy) }
    it { should have_many(:documents).through(:document_tag_appointments) }
    it { should have_many(:document_group_tag_appointments).dependent(:destroy) }
    it { should have_many(:document_groups).through(:document_group_tag_appointments) }
    it { should have_many(:employee_tag_appointments).dependent(:destroy) }
    it { should have_many(:employees).through(:employee_tag_appointments) }
    it { should have_many(:employee_group_tag_appointments).dependent(:destroy) }
    it { should have_many(:employee_groups).through(:employee_group_tag_appointments) }
    it { should have_many(:event_tag_appointments).dependent(:destroy) }
    it { should have_many(:events).through(:event_tag_appointments) }
    it { should have_many(:event_group_tag_appointments).dependent(:destroy) }
    it { should have_many(:event_groups).through(:event_group_tag_appointments) }
    it { should have_many(:exam_tag_appointments).dependent(:destroy) }
    it { should have_many(:exams).through(:exam_tag_appointments) }
    it { should have_many(:exam_group_tag_appointments).dependent(:destroy) }
    it { should have_many(:exam_groups).through(:exam_group_tag_appointments) }
    it { should have_many(:facility_tag_appointments).dependent(:destroy) }
    it { should have_many(:facilities).through(:facility_tag_appointments) }
    it { should have_many(:facility_group_tag_appointments).dependent(:destroy) }
    it { should have_many(:facility_groups).through(:facility_group_tag_appointments) }
    it { should have_many(:invoice_tag_appointments).dependent(:destroy) }
    it { should have_many(:invoices).through(:invoice_tag_appointments) }
    it { should have_many(:notification_tag_appointments).dependent(:destroy) }
    it { should have_many(:notifications).through(:notification_tag_appointments) }
    it { should have_many(:notification_group_tag_appointments).dependent(:destroy) }
    it { should have_many(:notification_groups).through(:notification_group_tag_appointments) }
    it { should have_many(:order_tag_appointments).dependent(:destroy) }
    it { should have_many(:orders).through(:order_tag_appointments) }
    it { should have_many(:order_group_tag_appointments).dependent(:destroy) }
    it { should have_many(:order_groups).through(:order_group_tag_appointments) }
    it { should have_many(:product_tag_appointments).dependent(:destroy) }
    it { should have_many(:products).through(:product_tag_appointments) }
    it { should have_many(:product_group_tag_appointments).dependent(:destroy) }
    it { should have_many(:product_groups).through(:product_group_tag_appointments) }
    it { should have_many(:project_tag_appointments).dependent(:destroy) }
    it { should have_many(:projects).through(:project_tag_appointments) }
    it { should have_many(:project_group_tag_appointments).dependent(:destroy) }
    it { should have_many(:project_groups).through(:project_group_tag_appointments) }
    it { should have_many(:purchase_tag_appointments).dependent(:destroy) }
    it { should have_many(:purchases).through(:purchase_tag_appointments) }
    it { should have_many(:purchase_item_tag_appointments).dependent(:destroy) }
    it { should have_many(:purchase_items).through(:purchase_item_tag_appointments) }
    it { should have_many(:question_tag_appointments).dependent(:destroy) }
    it { should have_many(:questions).through(:question_tag_appointments) }
    it { should have_many(:role_tag_appointments).dependent(:destroy) }
    it { should have_many(:roles).through(:role_tag_appointments) }
    it { should have_many(:service_tag_appointments).dependent(:destroy) }
    it { should have_many(:services).through(:service_tag_appointments) }
    it { should have_many(:service_group_tag_appointments).dependent(:destroy) }
    it { should have_many(:service_groups).through(:service_group_tag_appointments) }
    it { should have_many(:setting_tag_appointments).dependent(:destroy) }
    it { should have_many(:settings).through(:setting_tag_appointments) }
    it { should have_many(:setting_group_tag_appointments).dependent(:destroy) }
    it { should have_many(:setting_groups).through(:setting_group_tag_appointments) }
    it { should have_many(:statistic_tag_appointments).dependent(:destroy) }
    it { should have_many(:statistics).through(:statistic_tag_appointments) }
    it { should have_many(:stock_tag_appointments).dependent(:destroy) }
    it { should have_many(:stocks).through(:stock_tag_appointments) }
    it { should have_many(:stock_export_tag_appointments).dependent(:destroy) }
    it { should have_many(:stock_exports).through(:stock_export_tag_appointments) }
    it { should have_many(:stock_import_tag_appointments).dependent(:destroy) }
    it { should have_many(:stock_imports).through(:stock_import_tag_appointments) }
    it { should have_many(:stock_transfer_tag_appointments).dependent(:destroy) }
    it { should have_many(:stock_transfers).through(:stock_transfer_tag_appointments) }
    it { should have_many(:subscription_group_tag_appointments).dependent(:destroy) }
    it { should have_many(:subscription_groups).through(:subscription_group_tag_appointments) }
    it { should have_many(:supplier_tag_appointments).dependent(:destroy) }
    it { should have_many(:suppliers).through(:supplier_tag_appointments) }
    it { should have_many(:tag_task_appointments).dependent(:destroy) }
    it { should have_many(:tasks).through(:tag_task_appointments) }
    it { should have_many(:tag_task_group_appointments).dependent(:destroy) }
    it { should have_many(:task_groups).through(:tag_task_group_appointments) }
    # NOTE: TagTransactionAppointment is owned by the Transaction workstream:
    # `belongs_to :transaction` conflicts with ActiveRecord#transaction, so the
    # tag_transactions through-association cannot be declared until that model
    # is renamed. Re-add coverage then.
    it { should have_many(:tag_warehouse_appointments).dependent(:destroy) }
    it { should have_many(:warehouses).through(:tag_warehouse_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:key) }
  end
end
