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