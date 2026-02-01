// https://www.svgrepo.com/
// This Stimulus controller injects a list of SVG symbols into the DOM.
// This allows for easy reuse of SVG icons throughout the application.
// Each symbol can be referenced using the <use> element within an <svg> tag.
// How to use: <svg><use href="#facebook-square"></use></svg>.

import { Controller } from "@hotwired/stimulus"

export default class SvgController extends Controller {
  static targets = ["svgList"]

  initialize() {
    this.initTargets()
    this.initSvgSymbolListHTML()
  }

  initTargets() {
    if (this.hasSvgListTarget) { return };
    this.element.insertAdjacentHTML('beforeend', `<div data-${this.identifier}-target="svgList"></div>`)
  }

  initSvgSymbolListHTML() {
    if (!this.hasSvgListTarget) { return };
    this.svgListTarget.innerHTML = this.svgSymbolListHTML()
  }

  disconnect() {
    if (!this.hasSvgListTarget) { return };
    this.svgListTarget.innerHTML = "";
  }

  svgSymbolListHTML() {
    return `
      <svg style="display: none;">
        <symbol id="arrow-left" viewBox="0 0 1024 1024">
          <path d="M604.7 759.2l61.8-61.8L481.1 512l185.4-185.4-61.8-61.8L357.5 512z"/>
        </symbol>
        <symbol id="arrow-right" viewBox="0 0 1024 1024">
          <path d="M419.3 264.8l-61.8 61.8L542.9 512 357.5 697.4l61.8 61.8L666.5 512z"/>
        </symbol>
      </svg>
    `
  }
}
