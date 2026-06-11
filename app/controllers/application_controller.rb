class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :set_owner

  private

  def set_owner
    @owner = User.first
  end
end
