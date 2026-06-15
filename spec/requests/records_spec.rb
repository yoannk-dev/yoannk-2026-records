require "rails_helper"
require "cgi"

RSpec.describe "Records", type: :request do
  # owner = User.first (set by ApplicationController#set_owner)
  let!(:owner) { create(:user) }

  def owner_collection(record)
    create(:user_record, user: owner, record: record)
  end

  # ---------------------------------------------------------------------------
  # GET /
  # ---------------------------------------------------------------------------
  describe "GET /" do
    context "with no records in the collection" do
      it "returns 200 and an empty grid message" do
        get root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No records in the collection yet.")
      end
    end

    context "with records in the owner's collection" do
      let!(:record) { create(:record, genre: "Rock") }
      before { owner_collection(record) }

      it "displays the record" do
        get root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(CGI.escapeHTML(record.title))
      end

      it "filters by genre when genre param is present" do
        other = create(:record, genre: "Jazz")
        owner_collection(other)

        get root_path, params: { genre: "Rock" }
        expect(response.body).to include(CGI.escapeHTML(record.title))
        expect(response.body).not_to include(CGI.escapeHTML(other.title))
      end

      it "returns all records when genre param is absent" do
        other = create(:record, genre: "Jazz")
        owner_collection(other)

        get root_path
        expect(response.body).to include(CGI.escapeHTML(record.title))
        expect(response.body).to include(CGI.escapeHTML(other.title))
      end
    end
  end

  # ---------------------------------------------------------------------------
  # GET /records/:id
  # ---------------------------------------------------------------------------
  describe "GET /records/:id" do
    context "when the record is in the owner's collection" do
      let!(:record) { create(:record) }
      before { owner_collection(record) }

      it "returns 200 for unauthenticated visitors" do
        get record_path(record)
        expect(response).to have_http_status(:ok)
      end

      it "returns 200 for authenticated non-owners" do
        sign_in create(:user)
        get record_path(record)
        expect(response).to have_http_status(:ok)
      end

      it "renders the record's artist and title" do
        get record_path(record)
        expect(response.body).to include(CGI.escapeHTML(record.artist), CGI.escapeHTML(record.title))
      end
    end

    context "when the record does not exist" do
      it "returns 404" do
        get record_path(id: 999_999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # GET /records/new
  # ---------------------------------------------------------------------------
  describe "GET /records/new" do
    context "when not logged in" do
      it "redirects to the login page" do
        get new_record_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as the owner" do
      before { sign_in owner }

      it "returns 200" do
        get new_record_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # GET /records/discogs_lookup
  # ---------------------------------------------------------------------------
  describe "GET /records/discogs_lookup" do
    context "when not logged in" do
      it "redirects to the login page" do
        get records_discogs_lookup_path, params: { barcode: "123456789" }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as the owner" do
      before { sign_in owner }

      it "returns 400 when neither barcode nor catno is provided" do
        get records_discogs_lookup_path
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to include("error" => "invalid_input")
      end

      it "returns 503 when DISCOGS_TOKEN is not configured" do
        ClimateControl.silence { ENV.delete("DISCOGS_TOKEN") } rescue nil
        prev = ENV.delete("DISCOGS_TOKEN")
        get records_discogs_lookup_path, params: { barcode: "123456789" }
        ENV["DISCOGS_TOKEN"] = prev if prev
        expect(response).to have_http_status(:service_unavailable)
      end

      it "returns JSON result on success" do
        ENV["DISCOGS_TOKEN"] = "fake_token"
        stub_request(:get, /api\.discogs\.com/)
          .to_return(
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: {
              results: [{
                id: "1234", title: "Daft Punk - Discovery",
                year: "2001", genre: ["Electronic"], country: "FR",
                cover_image: "https://img.discogs.com/cover.jpg",
                format: ["LP"], catno: "V2 544 906-1",
                label: ["Virgin"], barcode: ["724354490613"]
              }]
            }.to_json
          )

        get records_discogs_lookup_path, params: { barcode: "724354490613" }
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["title"]).to eq("Discovery")
        expect(json["artist"]).to eq("Daft Punk")
      ensure
        ENV.delete("DISCOGS_TOKEN")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # POST /records
  # ---------------------------------------------------------------------------
  describe "POST /records" do
    let(:valid_params) do
      {
        record: {
          artist:     "Daft Punk",
          title:      "Discovery",
          label_name: "Virgin",
          condition:  "VG+"
        }
      }
    end

    context "when not logged in" do
      it "redirects to the login page" do
        post records_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as the owner" do
      before { sign_in owner }

      it "creates a record and redirects on success" do
        expect {
          post records_path, params: valid_params
        }.to change(Record, :count).by(1)
          .and change(UserRecord, :count).by(1)

        expect(response).to redirect_to(record_path(Record.last))
      end

      it "creates the associated label when label_name is provided" do
        expect {
          post records_path, params: valid_params
        }.to change(Label, :count).by(1)

        expect(Label.last.name).to eq("Virgin")
      end

      it "returns 422 when required fields are missing" do
        post records_path, params: { record: { artist: "", title: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not create a record when params are invalid" do
        expect {
          post records_path, params: { record: { artist: "", title: "" } }
        }.not_to change(Record, :count)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /logout
  # ---------------------------------------------------------------------------
  describe "DELETE /logout" do
    it "logs out and redirects to root" do
      sign_in owner
      delete destroy_user_session_path
      expect(response).to redirect_to(root_path)
    end
  end
end
