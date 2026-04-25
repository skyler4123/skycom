// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// -----------------------------------------------------------------------------------------------------
import * as Helpers from "controllers/helpers"

// 1. The Namespace
window.Helpers = Helpers;

// 2. Core Utilities
window.Cookie = Helpers.Cookie
window.setCookie = Helpers.setCookie
window.removeCookie = Helpers.removeCookie
window.fetchJson = Helpers.fetchJson
window.pathname = Helpers.pathname
window.addAttribute = Helpers.addAttribute
window.addAction = Helpers.addAction
window.translate = Helpers.translate
window.poll = Helpers.poll
window.openByPathname = Helpers.openByPathname
window.identifier = Helpers.identifier

// 3. Rails-style Collection Helpers
window.keys = Helpers.keys
window.values = Helpers.values
window.entries = Helpers.entries
window.each = Helpers.each
window.eachWithIndex = Helpers.eachWithIndex
window.map = Helpers.map
window.slice = Helpers.slice
window.transformValues = Helpers.transformValues
window.isPresent = Helpers.isPresent
window.isEmpty = Helpers.isEmpty
window.sort = Helpers.sort
window.pagination = Helpers.pagination
window.randomId = Helpers.randomId
window.cloneNewKey = Helpers.cloneNewKey
window.openModal = Helpers.openModal
window.closeModal = Helpers.closeModal
window.openPopover = Helpers.openPopover
window.form = Helpers.form
window.toast = Helpers.toast
window.selectOptionsHTML = Helpers.selectOptionsHTML
window.findById = Helpers.findById
window.Enums = Helpers.Enums
window.mergeObjectArrays = Helpers.mergeObjectArrays
window.editable = Helpers.editable
window.tooltip = Helpers.tooltip
window.popover = Helpers.popover
window.picture = Helpers.picture
window.dictionary = Helpers.dictionary
window.translate = Helpers.translate

// 4. Data Getters (Safe from Race Conditions)
// This allows you to use 'currentCompany()' as a variable that always fetches fresh data
window.currentCompanies = Helpers.currentCompanies
window.currentCompany = Helpers.currentCompany
window.currentBranches = Helpers.currentBranches
window.currentUser = Helpers.currentUser
window.isSignedIn = Helpers.isSignedIn
window.currentDepartments = Helpers.currentDepartments
window.currentRoles = Helpers.currentRoles