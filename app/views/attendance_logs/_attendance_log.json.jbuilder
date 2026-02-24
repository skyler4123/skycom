json.extract! attendance_log, :id, :company_group_id, :company_id, :customer_id, :logable_id, :logable_type, :period_id, :location, :id_address, :device_info, :notes, :created_at, :updated_at
json.url attendance_log_url(attendance_log, format: :json)
