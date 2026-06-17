# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Pages::RetailCashier", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }
  let(:warehouse) { create(:warehouse, company: company, branch: branch) }
  let(:page_record) { create(:page, company: company, branch: branch, target_role: :retail_cashier) }

  let!(:product_a) { create(:product, company: company, branch: branch, name: "Widget Alpha") }
  let!(:product_b) { create(:product, company: company, branch: branch, name: "Widget Beta") }
  let!(:product_c) { create(:product, company: company, branch: branch, name: "Widget Gamma") }

  let!(:stock_a) do
    Stock.create!(company:, warehouse:, product: product_a, quantity: 10, reserved_quantity: 0)
      .tap { |s| s.send(:sync_available_counter) }
  end
  let!(:stock_b) do
    Stock.create!(company:, warehouse:, product: product_b, quantity: 5, reserved_quantity: 0)
      .tap { |s| s.send(:sync_available_counter) }
  end
  let!(:stock_c) do
    Stock.create!(company:, warehouse:, product: product_c, quantity: 0, reserved_quantity: 0)
      .tap { |s| s.send(:sync_available_counter) }
  end

  before do
    sign_in(owner)
  end

  scenario "page loads and displays products gallery" do
    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    expect(page).to have_content(/Products Gallery/i, wait: 10)
    expect(page).to have_selector('[data-action*="addToCart"]', minimum: 3, wait: 10)
    expect(page).to have_content(product_a.name)
    expect(page).to have_content(product_b.name)
    expect(page).to have_content(product_c.name)
    expect(page).to have_content("Cart is empty")
  end

  scenario "adding and removing items from cart" do
    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    first('[data-action*="addToCart"]', wait: 10).click
    expect(page).to have_content(product_a.name)
    expect(page).to have_content("$0.00")
    expect(page).not_to have_content("Cart is empty")

    find("button", text: /close/i).click
    expect(page).to have_content("Cart is empty")
  end

  scenario "ORDER creates pending order and switches to COMPLETE PAYMENT" do
    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    first('[data-action*="addToCart"]', wait: 10).click

    click_button "ORDER"
    expect(page).to have_button("COMPLETE PAYMENT", wait: 10)
    expect(page).to have_button("Cancel")

    expect(Order.count).to eq(1)
    expect(Order.last.workflow_status).to eq("pending")
  end

  scenario "Cancel after ORDER returns to ORDER state" do
    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    first('[data-action*="addToCart"]', wait: 10).click
    click_button "ORDER"
    expect(page).to have_button("COMPLETE PAYMENT", wait: 10)

    click_button "Cancel"
    expect(page).to have_button("ORDER", wait: 10)
    expect(page).not_to have_button("COMPLETE PAYMENT")

    expect(Order.count).to eq(1)
  end

  scenario "COMPLETE PAYMENT processes order and clears cart" do
    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    first('[data-action*="addToCart"]', wait: 10).click
    click_button "ORDER"
    expect(page).to have_button("COMPLETE PAYMENT", wait: 10)

    click_button "COMPLETE PAYMENT"
    expect(page).to have_content("Cart is empty", wait: 10)
    expect(page).to have_button("ORDER", wait: 10)

    order = Order.last
    expect(order.workflow_status).to eq("paid")
    expect(Invoice.where(order_id: order.id)).to be_present
    expect(Payment.joins(:invoice).where(invoice: { order_id: order.id })).to be_present
  end

  scenario "cart is locked after ORDER is placed" do
    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    first('[data-action*="addToCart"]', wait: 10).click
    expect(page).to have_content(product_a.name)

    click_button "ORDER"
    expect(page).to have_button("COMPLETE PAYMENT", wait: 10)

    expect(page).to have_content("Qty: 1")
    expect(page).not_to have_selector('[data-action*="updateQty"]')
    expect(page).not_to have_selector("button", text: /close/i)
  end

  scenario "ORDER with insufficient stock shows error" do
    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    all('[data-action*="addToCart"]', wait: 10).last.click
    click_button "ORDER"

    expect(page).not_to have_button("COMPLETE PAYMENT", wait: 5)
    expect(page).to have_button("ORDER")
    expect(Order.count).to eq(0)
  end

  scenario "ORDER with empty cart shows warning" do
    visit "/companies/#{company.id}/pages/#{page_record.id}/retail_cashier"

    click_button "ORDER"

    expect(page).to have_button("ORDER")
    expect(page).not_to have_button("COMPLETE PAYMENT")
    expect(Order.count).to eq(0)
  end
end
