import Swal from 'sweetalert2'

import { isEmpty } from "controllers/helpers";
import ApplicationController from "controllers/application_controller";


export default class FlashController extends ApplicationController {
  static values = {
    messages: { type: Object, default: {} }, // Ex: { notice: "Hello World", error: "Something went wrong" }
  }

  initialize() {
    setTimeout(() => {
      if (!this.hasFlash()) { return }
      this.initValue()
    }, 500)
  }

  hasFlash() {
    return !isEmpty(ServerData.flash)
  }

  initValue() {
    this.messagesValue = ServerData.flash
  }

  messagesValueChanged(value, previousValue) {
    Object.entries(value).forEach(([type, message], index) => {
      setTimeout(() => {
        Swal.fire({
          position: "top",
          html: this.flashHTML(type, message),
          showConfirmButton: false,
          timer: 3000,
          backdrop: false,
          customClass: {
            container: '...1',
            popup: '!p-0',
            header: '...2',
            title: '...3',
            closeButton: '...',
            icon: '...',
            image: '...',
            htmlContainer: '!p-0',
            input: '...',
            inputLabel: '...',
            validationMessage: '...',
            actions: '...',
            confirmButton: '...',
            denyButton: '...',
            cancelButton: '...',
            loader: '...5',
            footer: '....6',
            timerProgressBar: '....7',
          }
        });
      }, 3000 * index)
    });
  }
  
  flashHTML(type = "notice", message) {
    switch (type) {
      case "error":
        return `<div class='w-full text-center py-2 px-3 bg-red-50 text-red-500 font-medium rounded-lg inline-block' id='error'>${message}</div>`
      case "info":
        return `<div class='w-full text-center py-2 px-3 bg-blue-50 text-blue-500 font-medium rounded-lg inline-block' id='info'>${message}</div>`
      case "alert":
        return `<div class='w-full text-center py-2 px-3 bg-red-50 text-red-500 font-medium rounded-lg inline-block' id='alert'>${message}</div>`
      case "warning":
        return `<div class='w-full text-center py-2 px-3 bg-yellow-50 text-yellow-500 font-medium rounded-lg inline-block' id='warning'>${message}</div>`
      case "notice":
        return `<div class='w-full text-center py-2 px-3 bg-green-50 text-green-500 font-medium rounded-lg inline-block' id='notice'>${message}</div>`
    }
  }

  reset() {}
}
