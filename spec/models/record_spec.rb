require "rails_helper"

RSpec.describe Record, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:label).optional }
    it { is_expected.to have_many(:user_records).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:user_records) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:artist) }
    it { is_expected.to validate_presence_of(:title) }
  end

  describe ".by_genre" do
    let!(:rock_record) { create(:record, genre: "Rock") }
    let!(:jazz_record) { create(:record, genre: "Jazz") }

    it "returns all records when genre is nil" do
      expect(Record.by_genre(nil)).to include(rock_record, jazz_record)
    end

    it "returns all records when genre is blank" do
      expect(Record.by_genre("")).to include(rock_record, jazz_record)
    end

    it "filters to the requested genre" do
      expect(Record.by_genre("Rock")).to include(rock_record)
      expect(Record.by_genre("Rock")).not_to include(jazz_record)
    end
  end

  describe ".recent" do
    let!(:older) { create(:record, created_at: 2.days.ago) }
    let!(:newer) { create(:record, created_at: 1.day.ago) }

    it "orders records by creation date descending" do
      expect(Record.recent.to_a).to eq([newer, older])
    end
  end

  describe ".for_page" do
    before { create_list(:record, 30) }

    it "limits results to PER_PAGE" do
      expect(Record.for_page(1).count).to eq(Record::PER_PAGE)
    end

    it "returns a different set on page 2" do
      page1 = Record.recent.for_page(1).to_a
      page2 = Record.recent.for_page(2).to_a
      expect(page1 & page2).to be_empty
    end
  end

  describe ".available_genres" do
    before do
      create(:record, genre: "Rock")
      create(:record, genre: "Jazz")
      create(:record, genre: "Rock")
      create(:record, genre: nil)
    end

    it "returns sorted unique non-nil genres" do
      expect(Record.available_genres).to eq(["Jazz", "Rock"])
    end
  end
end
