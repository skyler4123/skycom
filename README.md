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

  Seed::ApplicationService.run

  bin/rubocop --autocorrect-all 


  bundle exec rails g scaffold User email

  bundle exec rails g scaffold Company name description user:references parent_company_id
  bundle exec rails g scaffold Tag name description company_group:references
  bundle exec rails g scaffold TagMembership tag:references taggable:references{polymorphic} value description

  bundle exec rails g scaffold EmployeeGroup name company:references
  bundle exec rails g scaffold Employee name user:references company:references


  bundle exec rails g scaffold Role name
  bundle exec rails g scaffold UserRole user:references role:references
  bundle exec rails g scaffold Policy name resource action
  bundle exec rails g scaffold RolePolicy role:references policy:references


  bundle exec rails g scaffold RoleAppointment user:references appoint_to:references{polymorphic} role:references

  bundle exec rails g scaffold Address
  bundle exec rails g scaffold Category name user:references
  bundle exec rails g scaffold CategoryAppointment user:references appoint_to:references{polymorphic} category:references

  bundle exec rails g scaffold Session
  bundle exec rails g scaffold Event

  bundle exec rails g scaffold CompanyOwner user:references
  bundle exec rails g scaffold CompanyEntity name company_owner:references
  bundle exec rails g scaffold CompanyCategory
  bundle exec rails g scaffold CompanyEmployee
  bundle exec rails g scaffold CompanyRole
  bundle exec rails g scaffold CompanyPolicy
  bundle exec rails g scaffold CompanyCustomer
  bundle exec rails g scaffold CompanyFacility
  bundle exec rails g scaffold CompanyService

  bundle exec rails g scaffold ShopOwner

  bundle exec rails g scaffold RestaurantOwner

  bundle exec rails g scaffold AttendanceOwner
  bundle exec rails g scaffold AttendanceCategory
  bundle exec rails g scaffold AttendanceChecker
  bundle exec rails g scaffold AttendanceCheck
  bundle exec rails g scaffold AttendanceSummary

  bundle exec rails g scaffold ProductOwner
  bundle exec rails g scaffold ProductCategory
  bundle exec rails g scaffold ProductBrand
  bundle exec rails g scaffold ProductItem
  bundle exec rails g scaffold ProductCart

  bundle exec rails g scaffold NotificationOwner
  bundle exec rails g scaffold NotificationCategory
  bundle exec rails g scaffold NotificationEvent
  bundle exec rails g scaffold NotificationPolicy

  bundle exec rails g scaffold BookingOwner
  bundle exec rails g scaffold BookingCategory
  bundle exec rails g scaffold BookingItem
  bundle exec rails g scaffold BookingCustomer

  bundle exec rails g scaffold Calendar
  bundle exec rails g scaffold Chat
  bundle exec rails g scaffold Article
  bundle exec rails g scaffold Payment
  bundle exec rails g scaffold Project
  bundle exec rails g scaffold Report
##