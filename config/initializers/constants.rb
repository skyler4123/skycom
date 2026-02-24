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
  minus_12: -12,
  minus_11: -11,
  minus_10: -10,
  minus_9:  -9,
  minus_8:  -8,
  minus_7:  -7,
  minus_6:  -6,
  minus_5:  -5,
  minus_4:  -4,
  minus_3:  -3,
  minus_2:  -2,
  minus_1:  -1,
  utc:      0,
  plus_1:   1,
  plus_2:   2,
  plus_3:   3,
  plus_4:   4,
  plus_5:   5,
  plus_6:   6,
  plus_7:   7,
  plus_8:   8,
  plus_9:   9,
  plus_10:  10,
  plus_11:  11,
  plus_12:  12
}.freeze

CURRENCIE_CODES = {
  usd: 840,
  vnd: 704
}

COUNTRIE_CODES = {
  us: 840,
  vn: 704
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
