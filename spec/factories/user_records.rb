FactoryBot.define do
  factory :user_record do
    association :user
    association :record
    condition { %w[Mint VG+ VG G+].sample }
    added_at  { Time.current }
  end
end
