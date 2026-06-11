class RecordsController < ApplicationController
  PER_PAGE = 24

  def index
    base = @owner ? @owner.records.includes(:label) : Record.none
    base = base.by_genre(params[:genre]) if params[:genre].present?
    base = base.order(created_at: :asc)

    @genre    = params[:genre]
    @genres   = @owner ? @owner.records.distinct.pluck(:genre).compact.sort : []
    @page     = (params[:page] || 1).to_i
    @records  = base.limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
    @has_more = base.count > @page * PER_PAGE
  end

  def show
    @record      = @owner&.records&.find(params[:id])
    @user_record = @owner&.user_records&.find_by(record: @record)
  end

  def create
    authenticate_user!
  end
end
