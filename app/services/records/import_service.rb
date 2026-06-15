class Records::ImportService
  Result = Struct.new(:success?, :record, :user_record)

  def initialize(user, params)
    @user   = user
    @params = params
  end

  def call
    ActiveRecord::Base.transaction do
      @record      = build_record
      @record.save!
      @user_record = @user.user_records.create!(
        record:    @record,
        condition: @params[:condition].presence,
        added_at:  Time.current
      )
    end
    Result.new(true, @record, @user_record)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    Result.new(false, @record, nil)
  end

  private

  def build_record
    label = Label.find_or_create_by!(name: @params[:label_name]) if @params[:label_name].present?
    Record.new(
      artist:          @params[:artist],
      title:           @params[:title],
      year:            @params[:year].presence,
      genre:           @params[:genre].presence,
      country:         @params[:country].presence,
      format:          @params[:format].presence,
      catalog_number:  @params[:catalog_number].presence,
      barcode:         @params[:barcode].presence,
      cover_image_url: @params[:cover_image_url].presence,
      discogs_id:      @params[:discogs_id].presence,
      tracklist:       @params[:tracklist].present? ? JSON.parse(@params[:tracklist]) : nil,
      label:           label
    )
  end
end
