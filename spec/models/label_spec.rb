require "rails_helper"

RSpec.describe Label, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:records).dependent(:nullify) }
  end

  describe "validations" do
    subject { build(:label) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end
end
