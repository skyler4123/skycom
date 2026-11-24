require "rails_helper"

RSpec.describe "Homepage locales and SEO", type: :request do
  def alternate_links(body)
    Nokogiri::HTML(body).css('link[rel="alternate"][hreflang]').to_h do |link|
      [ link["hreflang"], link["href"] ]
    end
  end

  describe "GET /" do
    it "renders English with self-canonical and reciprocal hreflang" do
      get "/"

      expect(response).to have_http_status(:ok)
      document = Nokogiri::HTML(response.body)

      expect(document.at_css("html")["lang"]).to eq("en")
      expect(response.headers["Content-Language"]).to eq("en")
      expect(document.at_css('link[rel="canonical"]')["href"]).to eq("https://skyceer.com/")
      expect(alternate_links(response.body)).to eq(
        "en" => "https://skyceer.com/",
        "vi" => "https://skyceer.com/vi",
        "x-default" => "https://skyceer.com/"
      )
      expect(response.body).to include("One Account. Multiple Businesses.")

      json_ld = JSON.parse(document.at_css('script[type="application/ld+json"]').text)
      types = json_ld.fetch("@graph").map { |node| node.fetch("@type") }
      expect(types).to include("Organization", "WebSite", "SoftwareApplication")
    end

    it "keeps the existing private browser cache contract" do
      get "/"

      expect(response.headers["Cache-Control"]).to include("private")
      expect(response.headers["Cache-Control"]).to include("max-age=3600")
      expect(response.headers["Cache-Control"]).not_to include("public")
      expect(response.headers["Vary"]).to include("Cookie")
    end
  end

  describe "GET /vi" do
    it "renders Vietnamese with self-canonical and reciprocal hreflang" do
      get "/vi"

      expect(response).to have_http_status(:ok)
      document = Nokogiri::HTML(response.body)

      expect(document.at_css("html")["lang"]).to eq("vi")
      expect(response.headers["Content-Language"]).to eq("vi")
      expect(document.at_css('link[rel="canonical"]')["href"]).to eq("https://skyceer.com/vi")
      expect(alternate_links(response.body)).to eq(
        "en" => "https://skyceer.com/",
        "vi" => "https://skyceer.com/vi",
        "x-default" => "https://skyceer.com/"
      )
      expect(response.body).to include("Một tài khoản. Nhiều doanh nghiệp.")
      expect(response.body).not_to include("One Account. Multiple Businesses.")
    end

    it "keeps the existing private browser cache contract" do
      get "/vi"

      expect(response.headers["Cache-Control"]).to include("private")
      expect(response.headers["Cache-Control"]).to include("max-age=3600")
      expect(response.headers["Cache-Control"]).not_to include("public")
      expect(response.headers["Vary"]).to include("Cookie")
    end
  end

  describe "URL normalization" do
    it "redirects /en to the default locale root" do
      get "/en"

      expect(response).to have_http_status(:moved_permanently)
      expect(response.location).to end_with("/")
    end

    it "redirects /en/ to the default locale root" do
      get "/en/"

      expect(response).to have_http_status(:moved_permanently)
      expect(response.location).to end_with("/")
    end

    it "redirects /vi/ to the canonical locale path" do
      get "/vi/"

      expect(response).to have_http_status(:moved_permanently)
      expect(response.location).to end_with("/vi")
    end

    it "returns 404 for an unpublished locale" do
      get "/xx"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /sitemap.xml" do
    it "lists only the published locale homepages with matching alternates" do
      get "/sitemap.xml"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/xml")
      expect(response.body).to include("<loc>https://skyceer.com/</loc>")
      expect(response.body).to include("<loc>https://skyceer.com/vi</loc>")
      expect(response.body).to include('hreflang="en"')
      expect(response.body).to include('hreflang="vi"')
      expect(response.body).to include('hreflang="x-default"')
      expect(response.body).not_to include("/xx")
    end
  end

  describe "GET /robots.txt" do
    it "points crawlers at the sitemap" do
      get "/robots.txt"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/plain")
      expect(response.body).to include("Sitemap: https://skyceer.com/sitemap.xml")
      expect(response.body).not_to include("Disallow: /vi")
    end
  end
end
