import Swal from 'sweetalert2';
import dayjs from 'dayjs';
import { capitalize } from "controllers/helpers/data_helpers" 

// --- Formatting & Badges ---
export const timeFormat = (time, format = "DD/MM/YYYY") => {
  return dayjs(time).format(format)
}

export const statusBadge = (status) => {
  if (!status) return ""
  const statusKey = String(status).toLowerCase()
  let color = "slate"

  switch (statusKey) {
    case "active":
    case "confirmed":
    case "completed":
    case "paid":
      color = "green"; break
    case "in_progress":
      color = "blue"; break
    case "pending":
    case "suspended":
      color = "yellow"; break
    case "deleted":
    case "failed":
    case "refunded":
    case "cancelled":
      color = "red"; break
  }

  const styles = {
    green: { badge: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800", dot: "bg-green-600" },
    slate: { badge: "bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400 border border-slate-200 dark:border-slate-700", dot: "bg-slate-500" },
    yellow: { badge: "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400 border border-yellow-200 dark:border-yellow-800", dot: "bg-yellow-600" },
    red: { badge: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400 border border-red-200 dark:border-red-800", dot: "bg-red-600" },
    blue: { badge: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 border border-blue-200 dark:border-blue-800", dot: "bg-blue-600" }
  }

  const style = styles[color] || styles.slate
  const label = capitalize(statusKey.replace(/_/g, " "))

  return `
    <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${style.badge}">
      <span class="w-1.5 h-1.5 rounded-full ${style.dot}"></span> ${label}
    </span>
  `
}

// --- DOM Manipulation ---
export const toggleOpenAttribute = (element) => {
  if (element.hasAttribute('open')) {
    element.removeAttribute('open')
  } else {
    element.setAttribute('open', '')
  }
}

export const addAction = (element, action) => {
  const existingActions = element.getAttribute("data-action") || "";
  const actionSet = new Set(existingActions.split(" ").filter(Boolean));
  actionSet.add(action);
  element.setAttribute("data-action", Array.from(actionSet).join(" "));
}

export const addAttribute = (element, attribute, value) => {
  const existingAttributes = element.getAttribute(attribute) || "";
  const attributeSet = new Set(existingAttributes.split(" ").filter(Boolean));
  attributeSet.add(value);
  element.setAttribute(attribute, Array.from(attributeSet).join(" "));
}

// --- Modals & Popovers ---
export const openModal = ({html = "Model!", customClass = {}, options = {}}) => {
  Swal.fire({
    html: html,
    showConfirmButton: false,
    showCloseButton: false,
    backdrop: true,
    target: document.querySelector('main'),
    customClass: {
      container: '!bg-transparent',
      popup: '!p-0 !bg-transparent !w-full',
      htmlContainer: '!p-0 !overflow-visible',
      ...customClass
    },
    ...options,
  });
}

export const openPopover = ({parentElement, html = "Dialog content", position = 'bottom-center', className = ""}) => {
  const parentRect = parentElement.getBoundingClientRect();
  const parentTop = parentRect.top;
  const parentBottom = parentRect.bottom;
  const parentLeft = parentRect.left;
  const parentRight = parentRect.right;
  const parentWidth = parentRect.width;
  const parentHeight = parentRect.height;
    
  Swal.fire({
    html: html,
    position: 'top-start',
    showConfirmButton: false,
    showCloseButton: false,
    customClass: {
      container: '!bg-transparent',
      popup: 'swal2-container-custom w-fit! h-fit! p-0! rounded-none! bg-transparent!' + className,
      htmlContainer: '!p-0',
    },
    showClass: { popup: `animate__animated animate__fadeInUp animate__faster` },
    hideClass: { popup: `animate__animated animate__fadeOutDown animate__faster` },
    didOpen: (popupElement) => {
      const swalContainer = document.querySelector('.swal2-container-custom');
      swalContainer.style.position = 'absolute';
      
      switch (position) {
        case 'top-left':
          swalContainer.style.top = `${parentTop}px`; swalContainer.style.left = `${parentLeft}px`; break;
        case 'top-right':
          swalContainer.style.top = `${parentTop}px`; swalContainer.style.left = `${parentRight}px`; break;
        case 'top-center':
          swalContainer.style.top = `${parentTop}px`; swalContainer.style.left = `${parentLeft + parentWidth/2}px`; break;
        case 'bottom-left':
          swalContainer.style.top = `${parentBottom}px`; swalContainer.style.left = `${parentLeft}px`; break;
        case 'bottom-right':
          swalContainer.style.top = `${parentBottom}px`; swalContainer.style.left = `${parentRight}px`; break;
        case 'bottom-center':
          swalContainer.style.top = `${parentBottom}px`; swalContainer.style.left = `${parentLeft + parentWidth/2}px`; break;
        case 'left-center':
          swalContainer.style.top = `${parentTop + parentHeight/2}px`; swalContainer.style.left = `${parentLeft}px`; break;
        case 'right-center':
          swalContainer.style.top = `${parentTop + parentHeight/2}px`; swalContainer.style.left = `${parentRight}px`; break;
        case 'center-center':
          swalContainer.style.top = `${parentTop + parentHeight/2}px`; swalContainer.style.left = `${parentLeft + parentWidth/2}px`; break;
      }
    },
  });
}

export const closeSwal = () => Swal.close()
export const closeModal = () => Swal.close()

// --- Stimulus Attributes ---
export const darkmode = () => `data-controller="darkmode"`
export const openByPathname = () => `data-link-target="openByPathname"`
export const translate = (key) => `data-language-key="${key}"`
export const triggerLanguageDropdown = () => `data-language-target="triggerDropdown"`
export const languageCodeTextTarget = () => `data-language-target="codeText"`
export const addOpenTrigger = (key, index) => `data-open-target="trigger" data-action="click->open#click" data-open-key-param="${key}" data-open-index-param="${index}"`
export const addOpenListener = (key, index) => `data-open-target="listener" data-open-key-param="${key}" data-open-index-param="${index}"`
export const identifier = (controller) => {
  let identifier
  identifier = controller.name
  identifier = identifier.replace('Controller', '')
  identifier = identifier.replaceAll('_', 'NAMESPACE')
  identifier = identifier
  .match(/[A-Z]{2,}(?=[A-Z][a-z]+[0-9]*|\b)|[A-Z]?[a-z]+[0-9]*|[A-Z]|[0-9]+/g)
  .map(x => x.toLowerCase())
  .join('-');
  identifier = identifier.replaceAll('namespace', '')
  return identifier
}