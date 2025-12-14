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

  RAILS_MASTER_KEY=$(cat config/master.key) docker compose -f docker-compose.yml -f docker-compose.seed-test.yml up --abort-on-container-exit --exit-code-from web --attach web
  
  RAILS_MASTER_KEY=$(cat config/master.key) docker compose -f docker-compose.yml -f docker-compose.rspec-test.yml up --abort-on-container-exit --exit-code-from web --attach web

  Seed::ApplicationService.run
  Seed::ApplicationService.put_count
  
  bin/rubocop --autocorrect-all
  EDITOR="code --wait" bin/rails credentials:edit
  EDITOR="code --wait" bin/rails credentials:edit -e production
##

##
  ### Core Models
  bundle exec rails g scaffold User email
  bundle exec rails g migration AddDiscardedAtToUsers discarded_at:datetime:index
  bundle exec rails g scaffold CompanyGroup user:references name description code status:integer ownership_type:integer business_type:integer currency:integer registration_number:string vat_id:string address_line_1:string city:string postal_code:string country:string email:string phone_number:string website:string employee_count:integer fiscal_year_end_month:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Company company_group:references parent_company:references name description code status:integer ownership_type:integer business_type:integer currency:integer registration_number:string vat_id:string address_line_1:string city:string postal_code:string country:string email:string phone_number:string website:string employee_count:integer fiscal_year_end_month:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Address alpha2:string:index alpha3:string:index continent:string:index nationality:string:index region:string:index longitude:decimal latitude:decimal level_total:integer level_1:string:index level_2:string:index level_3:string:index level_4:string:index level_5:string:index level_6:string:index level_7:string:index level_8:string:index level_9:string:index level_10:string:index discarded_at:datetime --force
  
  ### Generic / Tagging
  bundle exec rails g scaffold Tag company_group:references name description code --force
  bundle exec rails g scaffold TagAppointment tag:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} value description --force

  ### HR / Permission Management
  bundle exec rails g scaffold Role company_group:references company:references model_type:integer name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Policy company_group:references company:references name description code resource action status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold PolicyAppointment policy:references appoint_to:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold RoleAppointment role:references appoint_to:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force
  
  bundle exec rails g scaffold Position name
  bundle exec rails g scaffold PaySlip name
  bundle exec rails g scaffold Attendance name

  ### HR / Employee Management
  bundle exec rails g scaffold EmployeeGroup company_group:references company:references name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Employee user:references company_group:references company:references name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold EmployeeGroupAppointment employee_group:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code --force
  bundle exec rails g scaffold EmployeeAppointment employee:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code --force

  ### CRM / Customer Management
  bundle exec rails g scaffold CustomerGroup company_group:references company:references name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Customer user:references company_group:references company:references name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold CustomerGroupAppointment customer_group:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold CustomerAppointment customer:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force

  ### Inventory
  bundle exec rails g scaffold Inventory company_group:references company:references education_type:integer hospital_type:integer hotel_type:integer restaurant_type:integer retail_type:integer name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold InventoryItem inventory:references education_type:integer hospital_type:integer hotel_type:integer restaurant_type:integer retail_type:integer name description code sku:string:index barcode:string:index upc:string:index ean:string:index manufacturer_code:string serial_number:string:index batch_number:string expiration_date:datetime status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold InventoryItemAppointment inventory_item:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold InventoryTransaction company_group:references company:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold InventoryTransactionAppointment inventory_transaction:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force

  ### Product Management
  bundle exec rails g scaffold Brand name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold ProductGroup company_group:references company:references education_type:integer hospital_type:integer hotel_type:integer restaurant_type:integer retail_type:integer name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Product company_group:references company:references brand:references education_type:integer hospital_type:integer hotel_type:integer restaurant_type:integer retail_type:integer name description code price:decimal currency:integer sku:string:index barcode:string:index upc:string:index ean:string:index manufacturer_code:string serial_number:string:index batch_number:string expiration_date:datetime status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold ProductGroupAppointment product_group:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold ProductAppointment product:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force

  ### Service Management
  bundle exec rails g scaffold ServiceGroup company_group:references company:references education_type:integer hospital_type:integer hotel_type:integer restaurant_type:integer retail_type:integer name description code status:integer duration:integer start_at:datetime business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Service company_group:references company:references education_type:integer hospital_type:integer hotel_type:integer restaurant_type:integer retail_type:integer name description code status:integer duration:integer start_at:datetime business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold ServiceGroupAppointment service_group:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer duration:integer start_at:datetime business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold ServiceAppointment service:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer duration:integer start_at:datetime business_type:integer discarded_at:datetime:index --force

  ### Orders
  bundle exec rails g scaffold OrderGroup company_group:references company:references customer:references education_type:integer hospital_type:integer hotel_type:integer restaurant_type:integer retail_type:integer name description code currency:integer duration:integer status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Order company_group:references company:references customer:references education_type:integer hospital_type:integer hotel_type:integer restaurant_type:integer retail_type:integer name description code sku:string:index barcode:string:index upc:string:index ean:string:index manufacturer_code:string serial_number:string:index batch_number:string expiration_date:datetime currency:integer duration:integer status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold OrderGroupAppointment order_group:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} unit_price:decimal quantity:integer total_price:decimal name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold OrderAppointment order:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} unit_price:decimal quantity:integer total_price:decimal name description code status:integer business_type:integer discarded_at:datetime:index --force

  ### Carts
  bundle exec rails g scaffold CartGroup company_group:references company:references name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Cart company_group:references company:references cart_group:references name description code sku:string:index barcode:string:index upc:string:index ean:string:index manufacturer_code:string serial_number:string:index batch_number:string expiration_date:datetime status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold CartAppointment cart:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force

  ### Purchase
  bundle exec rails g scaffold Purchase company_group:references company:references name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold PurchaseItem purchase:references name description code sku:string:index barcode:string:index upc:string:index ean:string:index manufacturer_code:string serial_number:string:index batch_number:string expiration_date:datetime status:integer business_type:integer discarded_at:datetime:index --force

  bundle exec rails g scaffold Promotion name

  ### Billing & Payments
  bundle exec rails g scaffold Invoice order:references name description code currency:integer duration:integer number total_price:decimal due_date:datetime status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Payment invoice:references name description code currency:integer duration:integer exchange_rate:decimal amount:decimal payment_method gateway_details status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold PaymentMethod name description code currency:integer status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold PaymentMethodAppointment payment_method:references company_group:references company:references name description code status:integer business_type:integer discarded_at:datetime:index --force

  bundle exec rails g scaffold Refund name
  bundle exec rails g scaffold Transaction name

  ### Operations & Logistics
  bundle exec rails g scaffold FacilityGroup company_group:references company:references education_type:integer hospital_type:integer hotel_type:integer restaurant_type:integer retail_type:integer name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Facility company_group:references company:references education_type:integer hospital_type:integer hotel_type:integer restaurant_type:integer retail_type:integer name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold FacilityGroupAppointment facility_group:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold FacilityAppointment facility:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force

  ### Project & Task Management
  bundle exec rails g scaffold ProjectGroup company_group:references company:references education_type:integer hospital_type:integer hotel_type:integer restaurant_type:integer retail_type:integer name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Project company_group:references company:references project_group:references education_type:integer hospital_type:integer hotel_type:integer restaurant_type:integer retail_type:integer name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold ProjectGroupAppointment project_group:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold ProjectAppointment project:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold TaskGroup company_group:references company:references education_type:integer hospital_type:integer hotel_type:integer restaurant_type:integer retail_type:integer name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Task company_group:references company:references task_group:references education_type:integer hospital_type:integer hotel_type:integer restaurant_type:integer retail_type:integer name description code currency:integer status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold TaskGroupAppointment task_group:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold TaskAppointment task:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force

  ### Booking & Scheduling
  bundle exec rails g scaffold Booking company_group:references company:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} education_type:integer hospital_type:integer hotel_type:integer restaurant_type:integer retail_type:integer name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Period company_group:references company:references education_type:integer hospital_type:integer hotel_type:integer restaurant_type:integer retail_type:integer name description code duration:integer start_at:datetime end_at:datetime expire_at:datetime discarded_at:datetime:index --force
  bundle exec rails g scaffold PeriodAppointment period:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code value --force

  ### Communication & Notifications
  bundle exec rails g scaffold NotificationGroup company_group:references company:references name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Notification notification_group:references company_group:references company:references name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold NotificationGroupAppointment notification_group:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold NotificationAppointment notification:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force
  
  bundle exec rails g scaffold Chat

  ### Exams
  bundle exec rails g scaffold ExamGroup company_group:references company:references name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Exam exam_group:references company_group:references company:references name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Question company_group:references company:references name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Answer question:references name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold ExamAppointment exam:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force

  ### Event
  bundle exec rails g scaffold EventGroup company_group:references company:references name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Event event_group:references company_group:references company:references name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold EventGroupAppointment event_group:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold EventAppointment event:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force

  ### Subscriptions
  bundle exec rails g scaffold SubscriptionGroup company_group:references company:references name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Subscription subscription_group:references company_group:references company:references name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold SubscriptionGroupAppointment subscription_group:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold SubscriptionAppointment subscription:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force

  ### Setting
  bundle exec rails g scaffold SettingGroup company_group:references company:references content:json name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Setting setting_group:references company_group:references company:references content:json name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold SettingGroupAppointment setting_group:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold SettingAppointment setting:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force

  ### Pricing
  bundle exec rails g scaffold Pricing country:integer region:integer nation:integer name description price:decimal code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold PricingAppointment pricing:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force

  ### Document
  bundle exec rails g scaffold DocumentGroup company_group:references company:references title content:json name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Document document_group:references company_group:references company:references title content:json name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold DocumentGroupAppointment document_group:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold DocumentAppointment document:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force

  ### Article
  bundle exec rails g scaffold ArticleGroup company_group:references company:references title content:json name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold Article article_group:references company_group:references company:references title content:json name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold ArticleGroupAppointment article_group:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force
  bundle exec rails g scaffold ArticleAppointment article:references appoint_from:references{polymorphic} appoint_to:references{polymorphic} appoint_for:references{polymorphic} appoint_by:references{polymorphic} name description code status:integer business_type:integer discarded_at:datetime:index --force

  ### Content & Knowledge Management
  bundle exec rails g scaffold Article
  bundle exec rails g scaffold Report
  bundle exec rails g scaffold Log name
##
