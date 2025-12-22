// --- Type Checks ---
/**
 * Checks if a value is defined (not undefined).
 * @param {*} x - The value to check.
 * @returns {boolean} True if defined, false otherwise.
 */
export const isDefined = (x) => typeof x !== 'undefined'

/**
 * Checks if a value is an array.
 * @param {*} x - The value to check.
 * @returns {boolean} True if it is an array, false otherwise.
 */
export const isArray = (x) => Array.isArray(x)

/**
 * Checks if a value is a string.
 * @param {*} x - The value to check.
 * @returns {boolean} True if it is a string, false otherwise.
 */
export const isString = (x) => (typeof x === 'string' || x instanceof String)

/**
 * Checks if a value is a number.
 * @param {*} x - The value to check.
 * @returns {boolean} True if it is a number, false otherwise.
 */
export const isNumber = (x) => typeof x === "number"

/**
 * Checks if a value is a plain object (not an array and not null).
 * @param {*} x - The value to check.
 * @returns {boolean} True if it is an object, false otherwise.
 */
export const isObject = (x) => {
  return typeof x === 'object' && !Array.isArray(x) && x !== null
}

/**
 * Checks if all values within an object are null or empty strings.
 * @param {object} object - The object to check.
 * @returns {boolean} True if all values are null or empty.
 */
export const isObjectNull = (object) => {
  return Object.values(object).every(x => x === null || x === "")
}

/**
 * Checks if a value is empty.
 * - Objects: Checks if all values are null/empty.
 * - Arrays: Checks if length is 0.
 * - Strings: Checks if empty string.
 * - Numbers: Returns false (numbers are considered not empty).
 * @param {*} x - The value to check.
 * @returns {boolean} True if empty, false otherwise.
 */
export const isEmpty = (x) => {
  if (isObject(x)) { return isObjectNull(x) }
  if (isArray(x)) { return x.length === 0 }
  if (isString(x)) { return x === "" }
  if (isNumber(x)) { return false }
  return true
}

// --- String ---
/**
 * Capitalizes the first letter of a string.
 * @param {string} string - The string to capitalize.
 * @returns {string} The capitalized string.
 */
export const capitalize = (string) => {
  if (!string) return ""
  return string.charAt(0).toUpperCase() + string.slice(1);
}

/**
 * Generates a random alphanumeric ID string.
 * @returns {string} A random ID.
 */
export const randomId = () => {
  return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
}

// --- Array / Object Manipulation ---
/**
 * Merges two arrays of objects based on a unique key.
 * Items in arrayB will overwrite items in arrayA if they share the same key.
 * @param {Array<object>} arrayA - The base array.
 * @param {Array<object>} arrayB - The array to merge in.
 * @param {string} [key="id"] - The property key to determine uniqueness.
 * @returns {Array<object>} The merged array.
 */
export const mergeObjectArrays = (arrayA, arrayB, key = "id") => {
  const mapA = new Map(arrayA.map(item => [item[key], item]));
  arrayB.forEach(itemB => {
    mapA.set(itemB[key], itemB);
  });
  return Array.from(mapA.values());
}

/**
 * Merges two arrays of primitives, removing duplicates.
 * @param {Array} arrayA - The first array.
 * @param {Array} arrayB - The second array.
 * @returns {Array} A new array containing unique elements from both arrays.
 */
export const mergeArrays = (arrayA, arrayB) => {
  // Create a Set from both arrays (automatically removes duplicates)
  // convert it back to an array
  return [...new Set([...arrayA, ...arrayB])];
}

/**
 * Returns elements from arrayA that are not present in arrayB, based on a key.
 * @param {Array<object>} arrayA - The source array.
 * @param {Array<object>} arrayB - The array containing items to exclude.
 * @param {string} [key="id"] - The property key to compare.
 * @returns {Array<object>} The filtered array.
 */
export const subtractObjectArrays = (arrayA, arrayB, key = "id") => {
  const keysToExclude = new Set(arrayB.map(item => item[key]));
  return arrayA.filter(itemA => !keysToExclude.has(itemA[key]));
}

/**
 * Returns elements from arrayA that are not present in arrayB (for primitives).
 * @param {Array} arrayA - The source array.
 * @param {Array} arrayB - The array containing items to exclude.
 * @returns {Array} The filtered array.
 */
export const subtractArrays = (arrayA, arrayB) => {
  // 1. Create a Set for O(1) lookup speed
  const exclude = new Set(arrayB);
  
  // 2. Filter returns a NEW array, leaving arrayA untouched
  return arrayA.filter(element => !exclude.has(element));
}

/**
 * Filters an array of objects based on a set of conditions.
 * @param {Array<object>} array - The array to filter.
 * @param {object} conditions - Key-value pairs to match. Values can be primitives or arrays of allowed values.
 * @returns {Array<object>} The filtered array.
 */
export const queryArray = (array, conditions) => {
  const keys = Object.keys(conditions);
  return array.filter(item => {
    return keys.every(key => {
      const conditionValue = conditions[key];
      const itemValue = item[key];
      if (Array.isArray(conditionValue)) {
        return conditionValue.includes(itemValue);
      } else {
        return itemValue === conditionValue;
      }
    });
  });
}

/**
 * Finds the first element in an array that matches a set of conditions.
 * @param {Array<object>} array - The array to search.
 * @param {object} conditions - Key-value pairs to match.
 * @returns {object|undefined} The found element or undefined.
 */
export const findArray = (array, conditions) => {
  const keys = Object.keys(conditions);
  return array.find(item => {
    return keys.every(key => {
      const conditionValue = conditions[key];
      const itemValue = item[key];
      if (Array.isArray(conditionValue)) {
        return conditionValue.includes(itemValue);
      } else {
        return itemValue === conditionValue;
      }
    });
  });
};

/**
 * Finds an object in an array by its 'id' property.
 * @param {Array<object>} array - The array to search.
 * @param {string|number} id - The ID to search for.
 * @returns {object|undefined} The found object or undefined.
 */
export const findById = (array, id) => array.find(item => item["id"] === id);

/**
 * Extracts a list of property values from an array of objects.
 * @param {Array<object>} array - The array of objects.
 * @param {string} [key="id"] - The property key to pluck.
 * @returns {Array} An array of values.
 */
export const pluck = (array, key = "id") => array.map(item => item[key]);

/**
 * Calculates the sum.
 * - If an array of numbers is passed, it sums the numbers.
 * - If an array of objects is passed with a key, it sums the values of that key.
 * @param {Array} arr - The data to sum.
 * @param {string} [key] - (Optional) The property key to use if summing objects.
 * @returns {number} The calculated sum.
 */
export const sum = (arr, key = null) => {
  if (!Array.isArray(arr)) return 0;

  return arr.reduce((total, current) => {
    // If a key is present, use the object's value; otherwise, use the item itself
    const value = key ? current[key] : current;

    // Convert to number to be safe (handles numeric strings), default to 0 if NaN
    const safeNumber = Number(value) || 0;

    return total + safeNumber;
  }, 0);
}

/**
 * Finds the element with the maximum value in an array.
 * @param {Array} arr - The array to search.
 * @param {string} [key=null] - The property key to compare if items are objects.
 * @returns {*} The element with the maximum value.
 */
export const max = (arr, key = null) => {
  if (!arr || arr.length === 0) return undefined;

  return arr.reduce((best, current) => {
    // Determine the values to compare based on whether a key is provided
    const bestValue = key ? best[key] : best;
    const currentValue = key ? current[key] : current;

    // Return the item (object or number) corresponding to the larger value
    return (bestValue > currentValue) ? best : current;
  });
}

/**
 * Finds the element with the minimum value in an array.
 * @param {Array} arr - The array to search.
 * @param {string} [key=null] - The property key to compare if items are objects.
 * @returns {*} The element with the minimum value.
 */
export const min = (arr, key = null) => {
  if (!arr || arr.length === 0) return undefined;

  return arr.reduce((best, current) => {
    // Extract the values to compare
    const bestValue = key ? best[key] : best;
    const currentValue = key ? current[key] : current;

    // Return the item (object or number) corresponding to the smaller value
    return (currentValue < bestValue) ? current : best;
  });
}