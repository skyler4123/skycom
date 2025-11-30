import { Controller } from "@hotwired/stimulus"

export default class ImgController extends Controller {
  static targets = ["img"]
  static values = {
    breakPoint: String, // Will be one of 'xs', 'sm', 'md', 'lg', 'xl', '2xl'
  }

  initialize() {
    this.checkWidth()
    this.resizeListener = this.checkWidth.bind(this)
    window.addEventListener("resize", this.resizeListener)
    this.initImgTargets()
  }

  disconnect() {
    window.removeEventListener("resize", this.resizeListener)
  }

  checkWidth() {
    const width = window.innerWidth
    let newBreakPoint

    if (width < 640) {
      newBreakPoint = 'xs'
    } else if (width >= 640 && width < 768) {
      newBreakPoint = 'sm'
    } else if (width >= 768 && width < 1024) {
      newBreakPoint = 'md'
    } else if (width >= 1024 && width < 1280) {
      newBreakPoint = 'lg'
    } else if (width >= 1280 && width < 1536) {
      newBreakPoint = 'xl'
    } else { // width >= 1536
      newBreakPoint = '2xl'
    }

    if (this.breakPointValue !== newBreakPoint) {
      this.breakPointValue = newBreakPoint
    }
  }
  initImgTargets() {
    this.element.querySelectorAll('img').forEach((imgElement) => {
      imgElement.setAttribute(`data-${this.identifier}-target`, (imgElement.getAttribute(`data-${this.identifier}-target`) || '') + ' img')
    })
  }

  /**
   * Called by Stimulus when the `breakPointValue` changes.
   *
   * Parameters:
   *  - value: the new breakpoint string (one of 'xs','sm','md','lg','xl','2xl')
   *  - previousValue: the prior breakpoint string (may be undefined/null on init)
   *
   * Behavior:
   *  - Logs the breakpoint transition when a previous value exists.
   *  - Iterates all image targets and reads a `data-srcset` attribute on each.
   *    The `data-srcset` should be a comma-separated list of items with the
   *    format: "<url> <breakpoint>" (e.g. "https://.../small.jpg sm, https://.../md.jpg md").
   *  - Chooses the url whose condition exactly matches the current breakpoint
   *    and assigns it to the image's `src` property.
   *
   * Notes / Edge cases:
   *  - `previousValue` may be falsy on the first invocation; logging is skipped in that case.
   *  - `data-srcset` items are split on commas, then each item is split on the
   *    first space to obtain `[url, condition]`. Items that don't match this
   *    shape are ignored.
   *  - If no entry matches the current breakpoint, the image `src` is left unchanged.
   *  - This method assumes image elements expose a `data-srcset` attribute
   *    with the expected format. It does not attempt to fall back to `srcset`
   *    or other responsive image mechanisms.
   *  - The controller's `initImgTargets()` helper is invoked first to ensure
   *    images are registered as Stimulus targets. That helper must make targets
   *    available on the element; otherwise querying for images should be done
   *    directly from the DOM.
   */
  breakPointValueChanged(value, previousValue) {
    if (!previousValue) return
    if (previousValue) {
      console.log(`Breakpoint changed from ${previousValue} to ${value}`)
    }
    this.initImgTargets().forEach((imgElement) => {
      const srcSet = imgElement.getAttribute("data-srcset")
      if (srcSet) {
        const srcSetItems = srcSet.split(",").map(item => item.trim())
        let selectedSrc = null

        srcSetItems.forEach(item => {
          const [url, condition] = item.split(" ")
          if (condition === value) {
            selectedSrc = url
          }
        })

        if (selectedSrc) {
          imgElement.src = selectedSrc
        }
      }
    })
  }
}
