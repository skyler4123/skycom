// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// -----------------------------------------------------------------------------------------------------
import * as Helpers from "controllers/helpers"

// 1. The Namespace
window.Helpers = Helpers;

// 2. Core Utilities
window.fetchJson = Helpers.fetchJson
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

// 4. Data Getters (Safe from Race Conditions)
// This allows you to use 'currentCompany()' as a variable that always fetches fresh data
window.currentCompanies = Helpers.currentCompanies
window.currentCompany = Helpers.currentCompany