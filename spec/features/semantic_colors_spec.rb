# frozen_string_literal: true

require "rails_helper"

# The semantic token layer in app/assets/tailwind/application.css is the only
# place theme colors live. This spec guards the mechanism itself:
#   - the same variable resolves to different values under .dark
#   - a semantic utility produces a real background color in both modes
#   - no `dark:` color class survives in rendered markup
#
# Regression coverage for the migration away from raw palette classes
# (bg-blue-600, text-slate-900, dark:bg-slate-800, ...). See
# docs/STYLING_GUIDELINES.md §1-3.
RSpec.feature "Semantic color tokens", type: :feature, js: true do
  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  before { sign_in(owner) }

  scenario "one variable drives light and dark without dark: classes" do
    visit demo_index_path
    expect(page).to have_content("Semantic color tokens", wait: 10)

    light_primary = page.evaluate_script(
      "getComputedStyle(document.querySelector('[data-palette-light]')).getPropertyValue('--primary').trim()"
    )
    dark_primary = page.evaluate_script(
      "getComputedStyle(document.querySelector('[data-palette-dark]')).getPropertyValue('--primary').trim()"
    )
    light_background = page.evaluate_script(
      "getComputedStyle(document.querySelector('[data-palette-light]')).getPropertyValue('--background').trim()"
    )
    dark_background = page.evaluate_script(
      "getComputedStyle(document.querySelector('[data-palette-dark]')).getPropertyValue('--background').trim()"
    )

    expect(light_primary).to be_present
    expect(dark_primary).to be_present
    expect(dark_primary).not_to eq(light_primary)
    expect(dark_background).not_to eq(light_background)

    # bg-primary resolves to a real color in both subtrees (not transparent).
    light_button_bg = page.evaluate_script(
      "getComputedStyle(document.querySelector('[data-palette-light] .bg-primary')).backgroundColor"
    )
    dark_button_bg = page.evaluate_script(
      "getComputedStyle(document.querySelector('[data-palette-dark] .bg-primary')).backgroundColor"
    )

    expect(light_button_bg).to be_present
    expect(light_button_bg).not_to eq("rgba(0, 0, 0, 0)")
    expect(dark_button_bg).to be_present
    expect(dark_button_bg).not_to eq("rgba(0, 0, 0, 0)")
    expect(dark_button_bg).not_to eq(light_button_bg)

    # The migration contract: no dark: color utilities in rendered markup.
    expect(page).to have_no_css('[class*="dark:bg-"], [class*="dark:text-"], [class*="dark:border-"]', visible: :all)
  end
end
