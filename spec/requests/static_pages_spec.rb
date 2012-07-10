require 'spec_helper'

describe "IndexPage" do
  describe "GET /index.html" do
    it "has the right banner" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      visit '/'
      page.should have_content('Welcome to the Stanford Geospatial Data Repository')
    end
  end
end
