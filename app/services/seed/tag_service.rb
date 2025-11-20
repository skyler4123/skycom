class Seed::TagService

  def self.run
    Company.all.each_with_index do |company, index|
      company.tags.create(
        name: "Tag #{index}",
        description: Faker::Movie.quote
      )
    end
  end
end
