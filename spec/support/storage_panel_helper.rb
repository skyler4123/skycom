# frozen_string_literal: true

# Shared measurements for storage page panels. Used by the storage feature
# specs to prove the white card fills the remaining page area (width and
# height) instead of hugging its content.
# - wrapperBottomGap: wrapper vs <main> bottom (grows with content, so use
#   <= for the "not short of the bottom" direction on short pages).
# - panelBottomGap: card vs wrapper bottom — pinpoints the card actually
#   stretching to the wrapper's bottom padding (negative when content
#   overflows, which is expected for long lists).
module StoragePanelHelper
  def panel_metrics
    page.evaluate_script(<<~JS)
      (() => {
        const main = document.querySelector("main")
        const panel = document.querySelector("[data-storage-panel]")
        if (!main || !panel) return { found: false }
        const wrapper = panel.parentElement
        const mainRect = main.getBoundingClientRect()
        const wrapperRect = wrapper.getBoundingClientRect()
        const panelRect = panel.getBoundingClientRect()
        return {
          found: true,
          widthCoverage: panelRect.width / mainRect.width,
          wrapperBottomGap: Math.round(mainRect.bottom - wrapperRect.bottom),
          panelBottomGap: Math.round(wrapperRect.bottom - panelRect.bottom),
        }
      })()
    JS
  end
end

RSpec.configure do |config|
  config.include StoragePanelHelper, type: :feature
end
