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
  Seed::ApplicationService.put_count
  
  bin/rubocop --autocorrect-all 


  bundle exec rails g scaffold User email
  bundle exec rails g migration AddDiscardedAtToUsers discarded_at:datetime:index

  bundle exec rails g scaffold Address alpha2:string:index alpha3:string:index continent:string:index nationality:string:index region:string:index longitude:decimal latitude:decimal level_total:integer level_1:string:index level_2:string:index level_3:string:index level_4:string:index level_5:string:index level_6:string:index level_7:string:index level_8:string:index level_9:string:index level_10:string:index discarded_at:datetime --force

  bundle exec rails g scaffold Company user:references parent_company:references name description status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Tag company:references name description --force
  bundle exec rails g scaffold TagAppointment tag:references appoint_to:references{polymorphic} value description --force

  bundle exec rails g scaffold EmployeeGroup company:references name description status:integer business_type:integer  discarded_at:datetime:index --force
  bundle exec rails g scaffold Employee user:references company:references name description status:integer business_type:integer  discarded_at:datetime:index --force
  bundle exec rails g scaffold EmployeeGroupAppointment employee_group:references appoint_to:references{polymorphic} name description --force



  bundle exec rails g scaffold Role company:references name description status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Policy company:references name description resource action status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold PolicyAppointment policy:references appoint_to:references{polymorphic} name description status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold RoleAppointment role:references appoint_to:references{polymorphic} name description status:integer business_type:integer discarded_at:datetime:index --force

  bundle exec rails g scaffold Facility
  bundle exec rails g scaffold Service
  bundle exec rails g scaffold Product


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