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