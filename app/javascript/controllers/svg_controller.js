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
      <svg xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" style="display:none">
        <symbol id="SVGRepo_bgCarrier" fill="#000000" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><g stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"><path d="M2,21h8a1,1,0,0,0,0-2H3.071A7.011,7.011,0,0,1,10,13a5.044,5.044,0,1,0-3.377-1.337A9.01,9.01,0,0,0,1,20,1,1,0,0,0,2,21ZM10,5A3,3,0,1,1,7,8,3,3,0,0,1,10,5Zm13,8.5v5a.5.5,0,0,1-.5.5h-1v2L19,19H14.5a.5.5,0,0,1-.5-.5v-5a.5.5,0,0,1,.5-.5h8A.5.5,0,0,1,23,13.5Z"></path></g></symbol>
      </svg>
    `
  }
}
