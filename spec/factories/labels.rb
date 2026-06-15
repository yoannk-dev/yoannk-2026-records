FactoryBot.define do
  factory :label do
    sequence(:name) { |n| "#{Faker::Music.genre} Records #{n}" }
  end
end
