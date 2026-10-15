# frozen_string_literal: true

class AddTitleBodyToPromoCampaigns < ActiveRecord::Migration[8.0]
  DEFAULT_TITLE = "Skycom gave you %{amount} credits!"
  DEFAULT_BODY = "Promo '%{name}' added %{amount} promo credits (cap %{max_cap}). Thank you for using Skycom! Here is our help to grow your business."

  def up
    add_column :promo_campaigns, :title, :string
    add_column :promo_campaigns, :body, :text

    PromoCampaign.reset_column_information
    PromoCampaign.where(title: nil).or(PromoCampaign.where(body: nil)).find_each do |campaign|
      amount = campaign.amount || 0
      max_cap = campaign.max_cap || 0
      name = campaign.name || "Promo"
      campaign.update_columns(
        title: campaign.title.presence || format(DEFAULT_TITLE, amount: amount),
        body: campaign.body.presence || format(DEFAULT_BODY, name: name, amount: amount, max_cap: max_cap)
      )
    end

    change_column_null :promo_campaigns, :title, false
    change_column_null :promo_campaigns, :body, false
  end

  def down
    remove_column :promo_campaigns, :title
    remove_column :promo_campaigns, :body
  end
end
