# frozen_string_literal: true

# Shared helpers for full-screen Operation consoles (POS, Reception, Store
# Manager, Inventory, ...). A console owns the whole viewport on desktop, so
# its body <main> and header row are measured against the document client
# width, which excludes the scrollbar.
module ConsoleLayoutHelper
  # Resizes the browser window for the duration of the block, then restores it.
  def with_window_size(width, height)
    page.driver.browser.manage.window.resize_to(width, height)
    yield
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  def console_layout_metrics
    page.evaluate_script(<<~JS)
      (() => {
        const main = document.querySelector("main")
        const headerRow = document.querySelector("header > div")
        return {
          main_width: main ? main.getBoundingClientRect().width : null,
          header_width: headerRow ? headerRow.getBoundingClientRect().width : null,
          viewport_width: document.documentElement.clientWidth,
          scroll_width: document.documentElement.scrollWidth
        }
      })()
    JS
  end
end

RSpec.configure do |config|
  config.include ConsoleLayoutHelper, type: :feature
end
