BUSINESS_TYPES = {
  # Group 1: General & Retail (0-999)
  retail: 0,
  service: 1,

  # Group 2: Food & Accommodation (1000-1999)
  restaurant: 1000,
  hotel: 1001,

  # Group 3: Medical (2000-2999)
  hospital: 2000,
  dental: 2001,
  optical: 2002,
  clinic: 2003,

  # Group 4: Education (3000-3999)
  education: 3000,
  university: 3001,
  english_center: 3002

  # Group 5: Specialized & Knowledge Services (3000-3999)
  # technology: 3000,
  # finance: 3001,
  # healthcare: 3002,
  # media: 3003,
  # real_estate: 3004,

  # Group 6: Professional Services (4000-4999)
  # legal: 4000,
  # consulting: 4001,
  # accounting: 4002,
  # marketing_agency: 4003,
  # human_resources: 4004,

  # Group 7: Physical & Production (5000-5999)
  # manufacturing: 5000,
  # construction: 5001,
  # transportation: 5002,
  # agriculture: 5003,
  # energy: 5004,
  # utilities: 5005,

  # Group 8: Public Sector & Non-Profit (6000-6999)
  # government_federal: 6000,
  # government_state_local: 6001,
  # military: 6002,
  # non_profit: 6003,
  # charity: 6004,

  # Group 9: Arts, Entertainment & Leisure (7000-7999)
  # entertainment: 7000,
  # arts_culture: 7001,
  # sports_fitness: 7002
}

TIMEZONES = {
  "-12": -12,
  "-11": -11,
  "-10": -10,
  "-9":  -9,
  "-8":  -8,
  "-7":  -7,
  "-6":  -6,
  "-5":  -5,
  "-4":  -4,
  "-3":  -3,
  "-2":  -2,
  "-1":  -1,
  "0":   0,
  "+1":  1,
  "+2":  2,
  "+3":  3,
  "+4":  4,
  "+5":  5,
  "+6":  6,
  "+7":  7,
  "+8":  8,
  "+9":  9,
  "+10": 10,
  "+11": 11,
  "+12": 12
}.freeze

CURRENCIE_CODES = {
  usd: 840,
  vnd: 704
}

COUNTRIE_CODES = {
  us: 840,
  vn: 704
}

SUBSCRIPTION_LIMITS = {
  max_of_companies: 3,
  max_of_employees: 5
}

LIFECYCLE_STATUS = {
  active: 0,
  inactive: 1,
  archived: 2,
  suspended: 3,
  deleted: 4
}

WORKFLOW_STATUS = {
  draft: 0,
  pending: 1,
  confirmed: 2,
  in_progress: 3,
  completed: 4,
  paid: 5,
  cancelled: 6,
  refunded: 7,
  failed: 8
}

SUBSCRIPTION_ENUM_PLANS = {
  temporary: 0,
  free: 1000,
  basic: 2000,
  basic_3m: 2001,
  basic_6m: 2002,
  basic_1y: 2003,
  pro: 3000,
  pro_3m: 3003,
  pro_6m: 3001,
  pro_1y: 3002,
  enterprise: 4000,
  enterprise_3m: 4001,
  enterprise_6m: 4002,
  enterprise_1y: 4003
}

SUBSCRIPTION_LIMITS = {
  temporary:     { employee: 3, company_group: 1, company: 2 },
  free:          { employee: 3, company_group: 1, company: 2 },
  basic:         { employee: 3, company_group: 1, company: 2 },
  basic_3m:      { employee: 3, company_group: 1, company: 2 },
  basic_6m:      { employee: 3, company_group: 1, company: 2 },
  basic_1y:      { employee: 3, company_group: 1, company: 2 },
  pro:           { employee: 3, company_group: 1, company: 2 },
  pro_3m:        { employee: 3, company_group: 1, company: 2 },
  pro_6m:        { employee: 3, company_group: 1, company: 2 },
  pro_1y:        { employee: 3, company_group: 1, company: 2 },
  enterprise:    { employee: 3, company_group: 1, company: 2 },
  enterprise_3m: { employee: 3, company_group: 1, company: 2 },
  enterprise_6m: { employee: 3, company_group: 1, company: 2 },
  enterprise_1y: { employee: 3, company_group: 1, company: 2 }
}

SUBSCRIPTION_PRICING_PLANS = {
  us: {
    temporary:     { amount: 0.00,    currency: :usd, duration: 1.day },
    free:          { amount: 0.00,    currency: :usd, duration: 1.months },
    basic:         { amount: 5.00,    currency: :usd, duration: 1.months }, # Default monthly
    basic_3m:      { amount: 14.00,   currency: :usd, duration: 3.months }, # ~7% discount
    basic_6m:      { amount: 27.00,   currency: :usd, duration: 6.months }, # ~10% discount
    basic_1y:      { amount: 50.00,   currency: :usd, duration: 1.year }, # ~17% discount
    pro:           { amount: 29.99,   currency: :usd, duration: 1.months }, # Default monthly
    pro_3m:        { amount: 85.00,   currency: :usd, duration: 3.months },
    pro_6m:        { amount: 170.00,  currency: :usd, duration: 6.months }, # ~5% discount
    pro_1y:        { amount: 325.00,  currency: :usd, duration: 1.year }, # ~10% discount
    enterprise:    { amount: 99.99,   currency: :usd, duration: 1.months },  # Default monthly
    enterprise_3m: { amount: 285.00,  currency: :usd, duration: 3.months },
    enterprise_6m: { amount: 570.00,  currency: :usd, duration: 6.months },
    enterprise_1y: { amount: 1100.00, currency: :usd, duration: 1.year }
  },
  vn: {
    temporary:     { amount: 0.00,       currency: :vnd, duration: 1.day },
    free:          { amount: 0,          currency: :vnd, duration: 1.months },
    basic:         { amount: 250_000,    currency: :vnd, duration: 1.months }, # Default monthly
    basic_3m:      { amount: 700_000,    currency: :vnd, duration: 3.months },
    basic_6m:      { amount: 1_350_000,  currency: :vnd, duration: 6.months },
    basic_1y:      { amount: 2_500_000,  currency: :vnd, duration: 1.year },
    pro:           { amount: 600_000,    currency: :vnd, duration: 1.months }, # Default monthly
    pro_3m:        { amount: 1_700_000,  currency: :vnd, duration: 3.months },
    pro_6m:        { amount: 3_400_000,  currency: :vnd, duration: 6.months },
    pro_1y:        { amount: 6_500_000,  currency: :vnd, duration: 1.year },
    enterprise:    { amount: 2_000_000,  currency: :vnd, duration: 1.months }, # Default monthly
    enterprise_3m: { amount: 5_700_000,  currency: :vnd, duration: 3.months },
    enterprise_6m: { amount: 11_000_000, currency: :vnd, duration: 6.months },
    enterprise_1y: { amount: 21_000_000, currency: :vnd, duration: 1.year }
  }
}.freeze
