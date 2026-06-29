class Record < ApplicationRecord
  PER_PAGE = 24

  attr_accessor :label_name
  belongs_to :label, optional: true
  has_many :user_records, dependent: :destroy
  has_many :users, through: :user_records

  validates :artist, :title, presence: true

  scope :by_genre,   ->(genre) { genre.present? ? where(genre: genre) : all }
  scope :search,     ->(q) { q.present? ? where("artist ILIKE :q OR title ILIKE :q", q: "%#{sanitize_sql_like(q.strip)}%") : all }
  scope :recent,     -> { order(created_at: :desc) }
  scope :by_artist,  -> { order(Arel.sql("LOWER(artist) ASC")) }
  scope :for_page,   ->(page) { limit(PER_PAGE).offset((page.to_i - 1) * PER_PAGE) }

  def self.available_genres
    distinct.pluck(:genre).compact.sort
  end
end
