class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :validatable

  has_many :user_records, dependent: :destroy
  has_many :records, through: :user_records
end
