require 'spec_helper'

describe CatalogController do

  before(:all) do
    # Add fixtures to solr here
    Dir.glob("#{::Rails.root}/spec/fixtures/*.xml") { |xml_doc| 
      puts "Ingesting: #{xml_doc}"
      `curl #{OgpRails::Application.config.solr_url}update?commit=true -F file=@#{xml_doc}`
      break
    }
  end
  
  after(:all) do
    `curl #{OgpRails::Application.config.solr_url}update?commit=true --data-binary '<delete><query>*:*</query></delete>'`
  end
    
  it '#get_metadata will get metadata in xml format' do
    visit "/getMetadata.xml?id=qw150nc3867&download=true" 
    assert page.find('title').should have_content('California Air Resources Board Air Basins')
    #puts page.body.inspect
  end 
  
  it '#get_metadata will get metadata in html format as a xsl transform out from xml' do
    visit "/getMetadata.html?id=qw150nc3867&download=true" 
    assert page.find('h1').should have_content('California Air Resources Board Air Basins')
    save_and_open_page
  end 
  
  it '#shorten_link will shorten link from UI' do
    visit "/shortenLink?link=http%3A%2F%2Fgeodata.tufts.edu%2FopenGeoPortalHome.jsp%3Flayer%255B%255D%3DHARVARD.SDE2.G3201_C82_1884_S8_SHEET1%26minX%3D-264.0234375%26minY%3D-85.051128779807%26maxX%3D264.0234375%26maxY%3D85.051128779807"
    assert page.has_content?('http://goo.gl/GJ5Gn')
    #puts page.body.inspect

  end

 
end
