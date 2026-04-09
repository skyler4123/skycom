export const calendarController = () => `data-controller="calendar"`

/**
 * Generates a kebab-case Stimulus controller identifier from a controller object/class.
 * It takes the controller's name, removes "Controller", and converts it to kebab-case.
 * @param {{name: string}} controllerObject - The Stimulus controller instance or class.
 * @returns {string} The kebab-case identifier.
 */
export const identifier = (controllerObject) => {
  let identifier
  identifier = controllerObject.name
  identifier = identifier.replace('Controller', '')
  identifier = identifier.replaceAll('_', 'NAMESPACE')
  identifier = identifier
  .match(/[A-Z]{2,}(?=[A-Z][a-z]+[0-9]*|\b)|[A-Z]?[a-z]+[0-9]*|[A-Z]|[0-9]+/g)
  .map(x => x.toLowerCase())
  .join('-');
  identifier = identifier.replaceAll('namespace', '')
  return identifier
}

export const openTrigger = (group, key) => `data-open-target="trigger" data-action="click->open#click" data-open-group-param="${group}" data-open-key-param="${key}"`

export const openListener = (group, key) => `data-open-target="listener" data-open-group-param="${group}" data-open-key-param="${key}"`

/**
 * Polls a callback function repeatedly until it returns true or max attempts are reached.
 * @param {Function} callback - The function to execute. Return `true` to stop polling.
 * @param {object} [options] - Polling configuration.
 * @param {number} [options.interval=100] - Time in ms between attempts.
 * @param {number} [options.maxAttempts=10] - Maximum number of times to call the callback.
 */
export const poll = (callback, { interval = 10, maxAttempts = 10 } = {}) => {
  let attempts = 0;
  const intervalId = setInterval(() => {
    attempts++;
    if (callback() === true || attempts >= maxAttempts) {
      clearInterval(intervalId);
    }
  }, interval);
};
