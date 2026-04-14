class Seed::TagService
  def self.create(
    company:,
    name: nil,
    description: Faker::Movie.quote
  )
    Tag.create!(
      company: company,
      name: name || Faker::Lorem.word,
      description: description
    )
  end
end
