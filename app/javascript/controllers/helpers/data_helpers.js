// --- Type Checks ---
export const isDefined = (x) => typeof x !== 'undefined'
export const isArray = (x) => Array.isArray(x)
export const isString = (x) => (typeof x === 'string' || x instanceof String)
export const isNumber = (x) => typeof x === "number"

export const isObject = (x) => {
  return typeof x === 'object' && !Array.isArray(x) && x !== null
}

export const isObjectNull = (object) => {
  return Object.values(object).every(x => x === null || x === "")
}

export const isEmpty = (x) => {
  if (isObject(x)) { return isObjectNull(x) }
  if (isArray(x)) { return x.length === 0 }
  if (isString(x)) { return x === "" }
  if (isNumber(x)) { return false }
  return true
}

// --- String ---
export const capitalize = (string) => {
  if (!string) return ""
  return string.charAt(0).toUpperCase() + string.slice(1);
}

export const randomId = () => {
  return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
}

// --- Array / Object Manipulation ---
export const mergeObjectArrays = (arrayA, arrayB, key = "id") => {
  const mapA = new Map(arrayA.map(item => [item[key], item]));
  arrayB.forEach(itemB => {
    mapA.set(itemB[key], itemB);
  });
  return Array.from(mapA.values());
}

export const mergeArrays = (arrayA, arrayB) => {
  // Create a Set from both arrays (automatically removes duplicates)
  // convert it back to an array
  return [...new Set([...arrayA, ...arrayB])];
}

export const subtractObjectArrays = (arrayA, arrayB, key = "id") => {
  const keysToExclude = new Set(arrayB.map(item => item[key]));
  return arrayA.filter(itemA => !keysToExclude.has(itemA[key]));
}

export const subtractArrays = (arrayA, arrayB) => {
  // 1. Create a Set for O(1) lookup speed
  const exclude = new Set(arrayB);
  
  // 2. Filter returns a NEW array, leaving arrayA untouched
  return arrayA.filter(element => !exclude.has(element));
}

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

export const findById = (array, id) => array.find(item => item["id"] === id);

export const pluck = (array, key = "id") => array.map(item => item[key]);

/**
 * Calculates the sum.
 * - If an array of numbers is passed, it sums the numbers.
 * - If an array of objects is passed with a key, it sums the values of that key.
 * * @param {Array} arr - The data to sum.
 * @param {string} [key] - (Optional) The property key to use if summing objects.
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