class Record < ApplicationRecord
  attr_accessor :label_name
  belongs_to :label, optional: true
  has_many :user_records, dependent: :destroy
  has_many :users, through: :user_records

  validates :artist, :title, presence: true

  scope :by_genre, ->(genre) { where(genre: genre) }
end
