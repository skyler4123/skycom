# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...


##
  rails new skycom --database=postgresql --css=tailwind

  rails generate authentication --omniauthable --passwordless --invitable

  docker compose up -d
  RAILS_MASTER_KEY=$(cat config/master.key) docker compose up -d

  bin/rubocop --autocorrect-all 
  bundle exec rails scaffold Role name user:references
  bundle exec rails scaffold RoleAppointment user:references appoint_to:references{polymorphic} role:references

  bundle exec rails scaffold Address
  bundle exec rails scaffold Category name user:references
  bundle exec rails scaffold CategoryAppointment user:references appoint_to:references{polymorphic} category:references

  bundle exec rails scaffold Session
  bundle exec rails scaffold Event

  bundle exec rails scaffold CompanyOwner user:references
  bundle exec rails scaffold CompanyEntity name company_owner:references
  bundle exec rails scaffold CompanyCategory
  bundle exec rails scaffold CompanyEmployee
  bundle exec rails scaffold CompanyRole
  bundle exec rails scaffold CompanyPolicy
  bundle exec rails scaffold CompanyCustomer
  bundle exec rails scaffold CompanyFacility
  bundle exec rails scaffold CompanyService

  bundle exec rails scaffold ShopOwner

  bundle exec rails scaffold RestaurantOwner

  bundle exec rails scaffold AttendanceOwner
  bundle exec rails scaffold AttendanceCategory
  bundle exec rails scaffold AttendanceChecker
  bundle exec rails scaffold AttendanceCheck
  bundle exec rails scaffold AttendanceSummary

  bundle exec rails scaffold ProductOwner
  bundle exec rails scaffold ProductCategory
  bundle exec rails scaffold ProductBrand
  bundle exec rails scaffold ProductItem
  bundle exec rails scaffold ProductCart

  bundle exec rails scaffold NotificationOwner
  bundle exec rails scaffold NotificationCategory
  bundle exec rails scaffold NotificationEvent
  bundle exec rails scaffold NotificationPolicy

  bundle exec rails scaffold BookingOwner
  bundle exec rails scaffold BookingCategory
  bundle exec rails scaffold BookingItem
  bundle exec rails scaffold BookingCustomer

  bundle exec rails scaffold Calendar
  bundle exec rails scaffold Chat
  bundle exec rails scaffold Article
  bundle exec rails scaffold Payment
  bundle exec rails scaffold Project
  bundle exec rails scaffold Report
##