require "rails_helper"

RSpec.describe "Owner managing records", type: :system do
  let!(:owner) { create(:user) }

  def login_as_owner
    visit new_user_session_path
    fill_in "Email",    with: owner.email
    fill_in "Password", with: "password123"
    click_button "Sign in"
    expect(page).to have_current_path(root_path)
  end

  describe "add-record button" do
    it "is not visible to a guest" do
      visit root_path
      expect(page).not_to have_button("Add new")
    end

    it "is visible after login", js: true do
      login_as_owner
      expect(page).to have_button("Add new")
    end
  end

  describe "adding a record via the form", js: true do
    before { login_as_owner }

    it "pre-fills and submits the new record form" do
      visit new_record_path(
        artist:  "Boards of Canada",
        title:   "Music Has the Right to Children",
        year:    "1998",
        genre:   "Electronic",
        country: "GB",
        format:  "LP"
      )

      expect(page).to have_field("record[artist]", with: "Boards of Canada")
      expect(page).to have_field("record[title]",  with: "Music Has the Right to Children")

      fill_in "record[label_name]", with: "Warp Records"
      select "VG+", from: "record[condition]"
      click_button "Add to Collection"
      # Wait for the turbo_stream to replace the panel with the show template
      expect(page).to have_css(".panel__title", text: "Music Has the Right to Children", wait: 5)
      expect(Record.last.artist).to eq("Boards of Canada")
    end

    it "does not save a record when required fields are blank" do
      visit new_record_path
      # Remove HTML5 `required` so the POST reaches Rails with blank values
      execute_script("document.querySelectorAll('[required]').forEach(el => el.removeAttribute('required'))")
      fill_in "record[artist]", with: ""
      fill_in "record[title]",  with: ""
      click_button "Add to Collection"

      # Server returns 422: no record is created and the form remains visible
      # (Server-side validation messages are tested in the request spec)
      expect(Record.count).to eq(0)
      expect(page).to have_button("Add to Collection", wait: 5)
    end
  end
end
