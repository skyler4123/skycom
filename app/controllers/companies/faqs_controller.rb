# frozen_string_literal: true

# System FAQ (Shell-First). Content lives in the FE content modules and is
# dynamically imported by Companies_Faqs_ShowController; this action only
# renders the layout shell. No records, writes, or credit deduction.
# Serves Stimulus: Companies_Faqs_ShowController
# Endpoints: GET /companies/:company_id/faq
class Companies::FaqsController < Companies::ApplicationController
  # Help content stays available while a suspended company recovers.
  skip_before_action :block_suspended_company

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
    end
  end
end
