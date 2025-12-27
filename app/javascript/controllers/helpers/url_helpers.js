/**
 * Generates the path for a specific retail POS branch.
 * @param {string|number} retailId - The ID of the retail company group.
 * @param {string|number} branchId - The ID of the branch.
 * @returns {string} The formatted path.
 */
export const retail_pos_branches_path = (retailId, branchId) => `/retail/${retailId}/pos/branches/${branchId}`
export const retail_management_branches_path = (retailId) => `/retail/${retailId}/management/branches`
export const edit_retail_management_branches_path = (retailId, branchId) => `/retail/${retailId}/management/branches/${branchId}`