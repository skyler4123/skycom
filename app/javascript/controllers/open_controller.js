// How to use:
// add 'data-open-target="trigger" data-action="click->open#click" data-open-key-param="uniqueKey" data-open-index-param="uniqueIndex"'
// add 'data-open-target="listener" data-open-key-param="uniqueKey" data-open-index-param="uniqueIndex"'

// click action will make controller loop through listener targets
// if their'key match to trigger'key, remove open attribute, then if they match with index param, set open attribute to true
// if their'key dont match with trigger's key, do nothing

// Example code:
//  <div data-controller="open"> --> This already added at server html
//    <a data-open-target="trigger" data-action="click->open#click" data-open-key-param="`key1`" data-open-index-param="`index1`">Trigger 1</a>
//    <a data-open-target="trigger" data-action="click->open#click" data-open-key-param="`key1`" data-open-index-param="`index2`">Trigger 2</a>
//    <a data-open-target="trigger" data-action="click->open#click" data-open-key-param="`key1`" data-open-index-param="`index3`">Trigger 3</a>
//    
//    <div data-open-target="listener" data-open-key-param="`key1`" data-open-index-param="`index1`">Listener 1</div>
//    <div data-open-target="listener" data-open-key-param="`key1`" data-open-index-param="`index2`">Listener 2</div>
//    <div data-open-target="listener" data-open-key-param="`key1`" data-open-index-param="`index3`">Listener 3</div>
//  </div>

import { Controller } from "@hotwired/stimulus"

export default class OpenController extends Controller {
  static targets = ["trigger", "listener"]

  click(event) {
    event.preventDefault()
    const triggerKey = event.params.key
    const triggerIndex = event.params.index
    if (!this.hasListenerTarget) { return }

    this.listenerTargets.forEach((listener) => {
      const listenerKey = listener.dataset.openKeyParam
      const listenerIndex = listener.dataset.openIndexParam
      if (listenerKey !== triggerKey) { return }
      
      listener.removeAttribute("open")
      if (String(listenerIndex) === String(triggerIndex)) {
        listener.setAttribute("open", true)
      }
    })
  }

}
