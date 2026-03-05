// How to use:
// add 'data-open-target="trigger" data-action="click->open#click" data-open-group-param="uniqueGroup" data-open-key-param="uniqueKey"'
// add 'data-open-target="listener" data-open-group-param="uniqueGroup" data-open-key-param="uniqueKey"'

// click action will make controller loop through listener targets
// if their'group match to trigger'group, remove open attribute, then if they match with key param, set open attribute to true
// if their'group dont match with trigger's group, do nothing

// Example code:
//  <div data-controller="open"> --> This already added at server html
//    <a data-open-target="trigger" data-action="click->open#click" data-open-group-param="`group1`" data-open-key-param="`key1`">Trigger 1</a>
//    <a data-open-target="trigger" data-action="click->open#click" data-open-group-param="`group1`" data-open-key-param="`key2`">Trigger 2</a>
//    <a data-open-target="trigger" data-action="click->open#click" data-open-group-param="`group1`" data-open-key-param="`key3`">Trigger 3</a>
//    
//    <div data-open-target="listener" data-open-group-param="`group1`" data-open-key-param="`key1`">Listener 1</div>
//    <div data-open-target="listener" data-open-group-param="`group1`" data-open-key-param="`key2`">Listener 2</div>
//    <div data-open-target="listener" data-open-group-param="`group1`" data-open-key-param="`key3`">Listener 3</div>
//  </div>

import { Controller } from "@hotwired/stimulus"

export default class OpenController extends Controller {
  static targets = ["trigger", "listener"]

  click(event) {
    event.preventDefault()

    const activeTriggerGroup = event.params.group
    const activeTriggerKey = event.params.key

    if (this.hasTriggerTarget) {
      this.triggerTargets.forEach((trigger) => {
        const triggerGroup = trigger.dataset.openGroupParam
        const triggerKey = trigger.dataset.openKeyParam
        if (String(triggerGroup) === String(activeTriggerGroup)) {
          trigger.removeAttribute("open")
        }
        if (String(triggerKey) === String(activeTriggerKey)) {
          trigger.setAttribute("open", true)
        }
      })
    }

    if (this.hasListenerTarget) {
      this.listenerTargets.forEach((listener) => {
        const listenerGroup = listener.dataset.openGroupParam
        const listenerKey = listener.dataset.openKeyParam
        if (listenerGroup !== activeTriggerGroup) { return }
        
        listener.removeAttribute("open")
        if (String(listenerKey) === String(activeTriggerKey)) {
          listener.setAttribute("open", true)
        }
      })
    }
  }

}
