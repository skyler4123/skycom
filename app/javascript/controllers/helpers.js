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

export const capitalize = (string) => {
  return string.charAt(0).toUpperCase() + string.slice(1);
}

/**
 * Merges two arrays of objects based on a specified key.
 * Elements in arrayB override elements in arrayA if the key matches.
 * New elements in arrayB are appended.
 *
 * @param {Array<Object>} arrayA The primary array (will be overwritten by B).
 * @param {Array<Object>} arrayB The array with merging/new elements.
 * @param {string} key The property key to use for matching elements (e.g., 'id').
 * @returns {Array<Object>} The merged array.
 * const A = [{id: 1, name: "a"},{id: 2, name: "b"}];
 * const B = [{id: 2, name: "bb"},{id: 3, name: "c"}];
 * const mergedArray = mergeObjectArraysByKey(A, B, "id");
 * console.log(mergedArray);
 * Expected Result: [ { id: 1, name: 'a' }, { id: 2, name: 'bb' }, { id: 3, name: 'c' } ]
 */
export const mergeObjectArrays = (arrayA, arrayB, key = "id") => {
  // 1. Create a Map from arrayA for O(1) lookup
  // The Map will store the key value as the map key and the object as the map value.
  const mapA = new Map(arrayA.map(item => [item[key], item]));

  // 2. Iterate through arrayB and update the map
  arrayB.forEach(itemB => {
    // itemB[key] is the value of the 'id' (or specified key) property.
    // .set() will override the existing value if the key exists (the merge/override logic)
    // or add a new entry if the key doesn't exist (the append logic).
    mapA.set(itemB[key], itemB);
  });

  // 3. Convert the Map values back to an array
  return Array.from(mapA.values());
}

/**
 * Merges arrayB into arrayA without duplicates.
 * Mutates arrayA and returns it.
 */
export const mergeArrays = (arrayA, arrayB) => {
  // Create a Set from arrayA for instant O(1) lookup
  const seen = new Set(arrayA);

  arrayB.forEach(element => {
    // Only append if the element is not already in the Set
    if (!seen.has(element)) {
      arrayA.push(element);
      
      // Update the Set to prevent duplicates if arrayB has repeats
      seen.add(element); 
    }
  });

  return arrayA;
}

/**
 * Filters arrayA to remove elements whose key matches any key in arrayB.
 * This is a set difference operation (A - B).
 *
 * @param {Array<Object>} arrayA The array to be filtered (the minuend).
 * @param {Array<Object>} arrayB The array containing keys to exclude (the subtrahend).
 * @param {string} key The property key to use for matching elements (e.g., 'id').
 * @returns {Array<Object>} The resulting array (A - B).
 * const A = [{id: 1, name: "a"},{id: 2, name: "b"}];
 * const B = [{id: 2, name: "bb"},{id: 3, name: "c"}];
 * const resultArray = subtractObjectArraysByKey(A, B, "id");
 * console.log(resultArray);
 *  Expected Result: [ { id: 1, name: 'a' } ]
 */
export const subtractObjectArrays = (arrayA, arrayB, key = "id") => {
  // 1. Create a Set of all key values from arrayB for O(1) existence check.
  // Set is used because checking Set.has(value) is much faster than array.includes(value).
  const keysToExclude = new Set(arrayB.map(item => item[key]));

  // 2. Filter arrayA
  // Keep only the elements from arrayA whose key value IS NOT in the keysToExclude Set.
  const resultArray = arrayA.filter(itemA => !keysToExclude.has(itemA[key]));

  return resultArray;
}

/**
 * Removes elements from arrayA that exist in arrayB.
 * Mutates arrayA and returns it.
 */
export const subtractArrays = (arrayA, arrayB) => {
  // 1. Create a Set from arrayB for instant O(1) lookup
  const exclude = new Set(arrayB);

  // 2. Loop backwards through arrayA
  // We loop backwards so removing an item doesn't mess up the indices of upcoming items
  for (let i = arrayA.length - 1; i >= 0; i--) {
    
    // 3. If the element exists in the exclusion set, remove it
    if (exclude.has(arrayA[i])) {
      arrayA.splice(i, 1);
    }
  }

  return arrayA;
}

/**
 * Queries an array of objects based on an object of conditions (key-value pairs).
 * Supports both single value matches (e.g., { gender: "male" }) and
 * array value matches (e.g., { id: [1, 2, 3] }).
 * An element is included in the result only if ALL conditions match.
 *
 * @param {Array<Object>} array The array of objects to query.
 * @param {Object} conditions An object where keys are the properties to check
 * and values are the required value OR an array of required values.
 * @returns {Array<Object>} A new array containing only the objects that match all conditions.
 */
export const queryArray = (array, conditions) => {
  const keys = Object.keys(conditions);

  return array.filter(item => {
    // Use .every() to ensure ALL conditions must pass
    return keys.every(key => {
      const conditionValue = conditions[key];
      const itemValue = item[key];

      // Check if the condition value is an array (the new functionality)
      if (Array.isArray(conditionValue)) {
        // Condition for IN LIST:
        // Check if the item's value is included in the list of allowed values
        return conditionValue.includes(itemValue);
      } else {
        // Condition for EQUALS:
        // Default behavior: check for a simple equality match
        return itemValue === conditionValue;
      }
    });
  });
}

/**
 * Finds the first object in an array that matches ALL conditions.
 * This is the most efficient approach as it stops searching upon the first match.
 *
 * @param {Array<Object>} array The array of objects to search through.
 * @param {Object} conditions An object containing the required key-value matches (including array matching).
 * @returns {Object | undefined} The first matching object, or undefined if no match is found.
 */
export const findArray = (array, conditions) => {
  const keys = Object.keys(conditions);

  return array.find(item => { // Changed from .filter() to .find()
    // Use .every() to ensure ALL conditions must pass
    return keys.every(key => {
      const conditionValue = conditions[key];
      const itemValue = item[key];

      // Check if the condition value is an array (IN LIST condition)
      if (Array.isArray(conditionValue)) {
        return conditionValue.includes(itemValue);
      } else {
        // Simple EQUALS condition
        return itemValue === conditionValue;
      }
    });
  });
};

/**
 * Finds and returns the first object in an array that matches the given ID value
 * for a specified key.
 *
 * @param {Array<Object>} array The array of objects to search through.
 * @param {any} id The ID value to match (e.g., 1, "abc", etc.).
 * @returns {Object | undefined} The first matching object, or undefined if no match is found.
 */

export const findById = (array, id) => {
  return array.find(item => item["id"] === id);
}

/**
 * Extracts (plucks) the value of a specified key from every object in an array.
 *
 * @param {Array<Object>} array The array of objects to process.
 * @param {string} key The property name whose values should be extracted.
 * @returns {Array<any>} A new array containing only the values of the specified key.
 */
export const pluck = (array, key = "id") => {
  // The map function iterates over every item and returns the result of the
  // function applied to it (item[key]).
  return array.map(item => item[key]);
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

export const currentUser = () => {
  return JSON.parse(Cookie('current_user'));
}

// check isSignedIn by check is_signed_in in cookie
export const isSignedIn = () => {
  return Cookie('is_signed_in') && Cookie('is_signed_in') === 'true'
}


export const companyGroups = () => {
  return JSON.parse(Cookie('company_groups'));
}

// currentCompanyGroup will be an element of companyGroups array when this element.id included in pathname
export const currentCompanyGroup = () => {
  const groups = companyGroups();
  const currentPath = pathname();

  // 1. Safety check: Ensure we actually have an array to iterate over
  if (!Array.isArray(groups)) {
    return null;
  }

  // 2. Find the element where the ID is included in the path
  // We wrap group.id in String() to ensure type safety (in case id is a number)
  return groups.find(group => currentPath.includes(String(group.id)));
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


// Function to open SweetAlert2 dialog based on a parent element
export const openPopover = ({parentElement, html = "Dialog content", position = 'bottom-center', className = ""}) => {
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
    position: 'top-start', // Use 'top-start' to position the dialog at the top-left corner, will adjust later by className
    showConfirmButton: false,
    showCloseButton: false,
    // backdrop: false,
    customClass: {
      container: '!bg-transparent',
      popup: 'swal2-container-custom w-fit! h-fit! p-0! rounded-none! bg-transparent!' + className,
      htmlContainer: '!p-0',
    },
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

export const closeSwal = () => {
  Swal.close()
}

export const closeModal = () => {
  Swal.close()
}

export const randomId = () => {
  return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
}

export const toggleOpenAttribute = (element) => {
  // add/remove attribute "open", not classList
  if (element.hasAttribute('open')) {
    element.removeAttribute('open')
  } else {
    element.setAttribute('open', '')
  }
}