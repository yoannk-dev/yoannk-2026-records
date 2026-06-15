require "rails_helper"

RSpec.describe "Browsing records", type: :system do
  let!(:owner)  { create(:user) }
  let!(:record) { create(:record, :with_cover, :with_tracklist, genre: "Rock") }
  let!(:other)  { create(:record, genre: "Jazz") }

  before do
    create(:user_record, user: owner, record: record)
    create(:user_record, user: owner, record: other)
  end

  describe "homepage" do
    it "shows the record grid" do
      visit root_path
      expect(page).to have_css(".cell", minimum: 2)
      expect(page).to have_content(record.title)
      expect(page).to have_content(other.title)
    end

    it "filters the grid when a genre chip is clicked", js: true do
      visit root_path
      click_link "Rock"
      expect(page).to have_content(record.title)
      expect(page).not_to have_content(other.title)
    end

    it "shows an empty state when the collection is empty" do
      UserRecord.delete_all
      Record.delete_all
      visit root_path
      expect(page).to have_content("No records in the collection yet.")
    end
  end

  describe "detail panel", js: true do
    # Use caption title text to locate a cell — avoids both CSS attribute selector issues
    # (Faker names with apostrophes/dashes) and sequence-dependent DOM ids.
    # .cell__caption-title has no text-transform so the raw title matches directly.
    def open_panel_for(rec)
      # Wait for the grid to be populated before clicking
      cell = find(".cell", text: rec.title, wait: 5)
      cell.find(".cell__btn").click
      expect(page).to have_css("aside#panel.panel--open", wait: 5)
    end

    it "opens when a record cell is clicked" do
      visit root_path
      open_panel_for(record)
      # .panel__artist uses label-uppercase (text-transform) so compare downcased
      expect(page).to have_css(".panel__artist", wait: 5)
      expect(find(".panel__artist").text.downcase).to eq(record.artist.downcase)
      expect(page).to have_css(".panel__title", text: record.title)
    end

    it "shows the tracklist inside the panel" do
      visit root_path
      open_panel_for(record)
      expect(page).to have_content("Track 1")
    end

    it "closes when the close button is clicked" do
      visit root_path
      open_panel_for(record)
      find("button[aria-label='Close panel']").click
      expect(page).not_to have_css("aside#panel.panel--open", wait: 3)
    end
  end
end
