class Seed::TagService
  def self.new(
    company:,
    key: nil,
    value: true,
    description: Faker::Movie.quote
  )
    Tag.new(
      company: company,
      key: key || Faker::Lorem.word,
      value: value,
      description: description
    )
  end

  def self.create(...)
    tag = new(...)
    tag.save!
    tag
  end
end
