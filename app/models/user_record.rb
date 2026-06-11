class UserRecord < ApplicationRecord
  belongs_to :user
  belongs_to :record

  validates :record_id, uniqueness: { scope: :user_id }
end
