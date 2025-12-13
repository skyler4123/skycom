import { Controller } from "@hotwired/stimulus"

export default class ResponsiveController extends Controller {
  // static values = {
  //   breakPoint: String, // Will be one of 'xs', 'sm', 'md', 'lg', 'xl', '2xl'
  // }

  // connect() {
  //   this.checkWidth()
  //   this.resizeListener = this.checkWidth.bind(this)
  //   window.addEventListener("resize", this.resizeListener)
  // }

  // disconnect() {
  //   window.removeEventListener("resize", this.resizeListener)
  // }

  // checkWidth() {
  //   const width = window.innerWidth
  //   let newBreakPoint

  //   if (width < 640) {
  //     newBreakPoint = 'xs'
  //   } else if (width >= 640 && width < 768) {
  //     newBreakPoint = 'sm'
  //   } else if (width >= 768 && width < 1024) {
  //     newBreakPoint = 'md'
  //   } else if (width >= 1024 && width < 1280) {
  //     newBreakPoint = 'lg'
  //   } else if (width >= 1280 && width < 1536) {
  //     newBreakPoint = 'xl'
  //   } else { // width >= 1536
  //     newBreakPoint = '2xl'
  //   }

  //   if (this.breakPointValue !== newBreakPoint) {
  //     this.breakPointValue = newBreakPoint
  //   }
  // }

  // breakPointValueChanged(value, previousValue) {
  //   if (previousValue) {
  //     console.log(`Breakpoint changed from ${previousValue} to ${value}`)
  //   }
  // }
}
