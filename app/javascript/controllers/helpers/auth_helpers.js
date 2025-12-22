import { pathname } from "controllers/helpers/http_helpers"

// --- Cookie Logic ---
export const Cookie = (name) => {
  let cookie = {}
  document.cookie.split(';').forEach(function(el) {
    let [k,v] = el.split('=');
    if (!k) return;
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

export const setCookie = (name, value, days) => {
  let expires = ""
  if (days) {
    let date = new Date()
    date.setTime(date.getTime() + (days*24*60*60*1000))
    expires = "; expires=" + date.toUTCString()
  }
  document.cookie = name + "=" + value + expires + "; path=/"
}

// --- User & Auth ---
export const currentUser = () => {
  const c = Cookie('current_user');
  return c ? JSON.parse(c) : null;
}

export const isSignedIn = () => {
  return Cookie('is_signed_in') && Cookie('is_signed_in') === 'true'
}

export const companyGroups = () => {
  const c = Cookie('company_groups');
  return c ? JSON.parse(c) : [];
}

export const currentCompanyGroup = () => {
  const groups = companyGroups();
  const currentPath = pathname();

  if (!Array.isArray(groups)) {
    return null;
  }
  return groups.find(group => currentPath.includes(String(group.id)));
}

// --- Paths ---
export const signInPath = () => `/sign_in`
export const signUpPath = () => `/sign_up`
export const signOutPath = () => `/sign_out`
// app/javascript/controllers/retail/pos/branches/show_controller.js
export const retailPosBranchPath = (retailId, branchId) => `/retail/${retailId}/pos/branches/${branchId}`