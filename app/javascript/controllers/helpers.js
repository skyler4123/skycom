import Swal from 'sweetalert2';
import dayjs from 'dayjs'

export const isDefined = (x) => {
  return typeof x !== 'undefined'  
}

export const isEmpty = (x) => {
  if (isObject(x)) { return isObjectNull(x) }
  if (isArray(x)) { return x.length === 0 }
  if (isString(x)) { return x === "" }
  if (isNumber(x)) { return false }
  return true
}

export const isObject = (x) => {
  return typeof x === 'object' && !Array.isArray(x) && x !== null
}

export const isObjectNull = (object) => {
  return isArraytNull(Object.values(object))
}

export const isArray = (x) => {
  return Array.isArray(x)
}

export const isString = (x) => {
  return (typeof x === 'string' || x instanceof String)
}

export const isNumber = (x) => {
  return typeof x === "number"
}



// get Cookie object
export const Cookie = (name) => {
  let cookie = {}
  document.cookie.split(';').forEach(function(el) {
    let [k,v] = el.split('=');
    let value = decodeURIComponent(v);
    value = value.replace("+", ' ');
    cookie[k.trim()] = value;
  })
  if (name) {
    return cookie[name]
  } else {
    return cookie
  }
}

// set Cookie object
export const setCookie = (name, value, days) => {
  let expires = ""
  if (days) {
    let date = new Date()
    date.setTime(date.getTime() + (days*24*60*60*1000))
    expires = "; expires=" + date.toUTCString()
  }
  document.cookie = name + "=" + value + expires + "; path=/"
}

// check isSignedIn by check is_signed_in in cookie
export const isSignedIn = () => {
  return Cookie('is_signed_in') && Cookie('is_signed_in') === 'true'
}

export const avatar = () => {
  return Cookie('avatar')
}
export const email = () => {
  return Cookie('email')
}




// Function to open SweetAlert2 dialog based on a parent element
export const openPopover = ({parentElement, html = "Dialog content", position = 'bottom-center-center', popupClass = ""}) => {
  // Get the parent element's position and dimensions
  const parentRect = parentElement.getBoundingClientRect();
  const parentTop = parentRect.top;
  const parentBottom = parentRect.bottom;
  const parentLeft = parentRect.left;
  const parentRight = parentRect.right;
  const parentWidth = parentRect.width;
  const parentHeight = parentRect.height;
    
  // Customize SweetAlert2 dialog
  Swal.fire({
    html: html,
    position: 'top-start', // Use 'top-start' to position the dialog at the top-left corner
    showConfirmButton: false,
    showCloseButton: false,
    // backdrop: false,
    customClass: {
      container: '!bg-transparent',
      popup: 'swal2-container-custom ' + popupClass,
      htmlContainer: '!p-0',
    },
    didOpen: (popupElement) => {
      // Adjust the dialog's position based on the parent element
      const swalContainer = document.querySelector('.swal2-container-custom');
      swalContainer.style.position = 'absolute';
      switch (position) {
        case 'top-left':
          swalContainer.style.top = `${parentTop}px`;
          swalContainer.style.left = `${parentLeft}px`;
          break;
        case 'top-right':
          swalContainer.style.top = `${parentTop}px`;
          swalContainer.style.left = `${parentRight}px`;
          break;
        case 'top-center':
          swalContainer.style.top = `${parentTop}px`;
          swalContainer.style.left = `${parentLeft + parentWidth/2}px`;
          break;

        case 'bottom-left':
          swalContainer.style.top = `${parentBottom}px`;
          swalContainer.style.left = `${parentLeft}px`;
          break;
        case 'bottom-right':
          swalContainer.style.top = `${parentBottom}px`;
          swalContainer.style.left = `${parentRight}px`;
          break;
        case 'bottom-center':
          swalContainer.style.top = `${parentBottom}px`;
          swalContainer.style.left = `${parentLeft + parentWidth/2}px`;
          break;

        case 'left-center':
          swalContainer.style.top = `${parentTop + parentHeight/2}px`;
          swalContainer.style.left = `${parentLeft}px`;
          break;
        case 'right-center':
          swalContainer.style.top = `${parentTop + parentHeight/2}px`;
          swalContainer.style.left = `${parentRight}px`;
          break;
        case 'center-center':
          swalContainer.style.top = `${parentTop + parentHeight/2}px`;
          swalContainer.style.left = `${parentLeft + parentWidth/2}px`;
          break;
      }
    },
  });
}

export const openModal = ({html = "Model!", customClass = {}, options = {}}) => {
  Swal.fire({
    html: html,
    showConfirmButton: false,
    showCloseButton: false,
    backdrop: true,
    target: document.querySelector('main'), // Default target
    customClass: {
      container: '!bg-transparent',
      popup: '!p-0 !bg-transparent !w-full',
      htmlContainer: '!p-0 !overflow-visible',
      ...customClass
    },
    ...options,
  });
}

export const openDrawer = ({html = "Drawer!", position = "top-start", popupClass = ""}) => {
  Swal.fire({
    html: html,
    position: position,
    showConfirmButton: false,
    showCloseButton: false,
    backdrop: true,
    showClass: {
      popup: `
        animate__animated
        animate__fadeInUp
        animate__faster
      `
    },
    hideClass: {
      popup: `
        animate__animated
        animate__fadeOutDown
        animate__faster
      `
    },
    customClass: {
      container: '!p-0',
      popup: 'swal2-container-custom h-screen',
      htmlContainer: '!p-0',
    },
  });
}

export const openFlash = (html, option = {}) => {
  Swal.fire({
    position: "top",
    html: html,
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
    },
    ...option
  });
}

export const pathname = () => {
  return window.location.pathname
}

export const href = () => {
  return window.location.href
}

export const origin = () => {
  return window.location.origin
}

export const timeFormat = (time, format = "DD/MM/YYYY") => {
  return dayjs(time).format(format)
}