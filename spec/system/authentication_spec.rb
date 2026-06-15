require "rails_helper"

RSpec.describe "Authentication", type: :system do
  let!(:owner) { create(:user) }

  describe "guest access" do
    it "can visit the homepage" do
      visit root_path
      expect(page).to have_css(".app")
    end

    it "is redirected to login when accessing the new record form" do
      visit new_record_path
      expect(page).to have_current_path(new_user_session_path)
    end

    it "does not see the add-record button" do
      visit root_path
      expect(page).not_to have_button("Add new")
    end
  end

  describe "login form" do
    it "logs in with valid credentials and redirects to root" do
      visit new_user_session_path
      fill_in "Email",    with: owner.email
      fill_in "Password", with: "password123"
      click_button "Sign in"
      expect(page).to have_current_path(root_path)
    end

    it "shows an error with invalid credentials" do
      visit new_user_session_path
      fill_in "Email",    with: owner.email
      fill_in "Password", with: "wrong_password"
      click_button "Sign in"
      expect(page).to have_content("Invalid")
    end
  end

  describe "owner-only UI after login" do
    it "shows the Add new button after successful login" do
      visit new_user_session_path
      fill_in "Email",    with: owner.email
      fill_in "Password", with: "password123"
      click_button "Sign in"
      expect(page).to have_button("Add new")
    end
  end

  describe "logout" do
    # No visible logout link in the UI (single-owner app).
    # DELETE /logout is covered by the request spec.
    # Here we verify Warden's session teardown clears the owner-only UI.
    it "clears the session and hides owner actions" do
      login_as(owner, scope: :user)
      visit root_path
      expect(page).to have_button("Add new")

      logout(:user)
      visit root_path
      expect(page).not_to have_button("Add new")
    end
  end
end
