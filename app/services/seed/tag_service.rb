class Seed::TagService
  def self.create(
    company:,
    key: nil,
    value: true,
    description: Faker::Movie.quote
  )
    Tag.create!(
      company: company,
      key: key || Faker::Lorem.word,
      value: value,
      description: description
    )
  end
end
