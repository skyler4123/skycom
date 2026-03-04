// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// -----------------------------------------------------------------------------------------------------
import * as Helpers from "controllers/helpers"
window.Helpers = Helpers;