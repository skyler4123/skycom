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

export const currentCompanyGroupId = () => {
  return Cookie('current_company_group_id')
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