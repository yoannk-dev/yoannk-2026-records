require "rails_helper"

RSpec.describe UserRecord, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:record) }
  end

  describe "validations" do
    describe "record uniqueness scoped to user" do
      let(:user)   { create(:user) }
      let(:record) { create(:record) }

      it "prevents adding the same record twice for the same user" do
        create(:user_record, user: user, record: record)
        duplicate = build(:user_record, user: user, record: record)
        expect(duplicate).not_to be_valid
      end

      it "allows the same record in different users' collections" do
        other_user = create(:user)
        create(:user_record, user: user, record: record)
        different_owner = build(:user_record, user: other_user, record: record)
        expect(different_owner).to be_valid
      end
    end
  end
end
