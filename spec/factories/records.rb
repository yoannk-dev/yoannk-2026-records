FactoryBot.define do
  factory :record do
    artist  { Faker::Music.band }
    title   { Faker::Music.album }
    year    { Faker::Number.between(from: 1950, to: 2024) }
    format  { %w[LP EP Single].sample }
    genre   { %w[Rock Jazz Soul Electronic].sample }
    country { Faker::Address.country_code }
    association :label

    trait :with_tracklist do
      tracklist do
        {
          "a" => ["Track 1", "Track 2", "Track 3"],
          "b" => ["Track 4", "Track 5", "Track 6"]
        }
      end
    end

    trait :with_cover do
      cover_image_url { "https://img.discogs.com/#{SecureRandom.hex(8)}.jpg" }
    end
  end
end
