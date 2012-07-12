require 'spec_helper'

describe CatalogController do

  before(:all) do
    # Add fixtures to solr here
    Dir.glob("#{::Rails.root}/spec/fixtures/*.xml") { |xml_doc| 
      cmd = "curl #{OgpRails::Application.config.solr_url}update?commit=true -F file=@\"#{xml_doc}\""
      puts "Executing: #{cmd}"
      `#{cmd}`
    }
  end
  
  after(:all) do
    cmd = "curl #{OgpRails::Application.config.solr_url}update?commit=true --data-binary '<delete><query>*:*</query></delete>'"
    puts "Deleting solr records: #{cmd}"
    `#{cmd}`
  end
    
  it '#get_metadata will get metadata in xml format' do
    visit "/getMetadata.xml?id=qw150nc3867" 
    assert page.find('title').should have_content('California Air Resources Board Air Basins')
    #puts page.body.inspect
  end 
  
  it '#get_metadata will get metadata in html format as a xsl transform out from xml' do
    visit "/getMetadata.html?id=qw150nc3867" 
    assert page.find('h1').should have_content('California Air Resources Board Air Basins')
    #save_and_open_page
  end 
 
  it '#get_feature_info will proxy a wms feature info call to geoserver instances for the given layer at a given point in html format' do
    bbox = '-13799573.846569,4355294.138711,-13412496.735387,4771111.572525'
    visit "/featureInfo.html?OGPID=bg073np4693&bbox=#{bbox}&x=252&y=272&height=680&width=633"
    assert page.find(:xpath, "//table[@class='featureInfo']").should have_content('fid')
    #puts page.body.inspect
  end
 
  it '#get_feature_info will proxy a wms feature info call to geoserver instances for the given layer at a given point in gml format' do
    bbox = '-13799573.846569,4355294.138711,-13412496.735387,4771111.572525'
    # This is very specific to GeoServer's implementation. This return bounding box is in GML format and 
    # encloses the result set. 
    gz374bz4826_feature_info = Nokogiri::XML(File.new(File.expand_path(File.dirname(__FILE__)  + '../../fixtures/gz374bz4826_feature_info.gml')))
    visit "/featureInfo.gml?OGPID=gz374bz4826&bbox=-13630370.558427,4547316.888801,-13629992.553435,4547826.867099&x=169&y=460&height=854&width=633"
    assert Nokogiri::XML(page.body).remove_namespaces!.xpath("featureCollection").should be_equivalent_to(gz374bz4826_feature_info.xpath("featureCollection"))
  end
 
  it '#shorten_link will shorten link from UI' do
    visit "/shortenLink?link=http%3A%2F%2Fgeodata.tufts.edu%2FopenGeoPortalHome.jsp%3Flayer%255B%255D%3DHARVARD.SDE2.G3201_C82_1884_S8_SHEET1%26minX%3D-264.0234375%26minY%3D-85.051128779807%26maxX%3D264.0234375%26maxY%3D85.051128779807"
    assert page.has_content?('http://goo.gl/GJ5Gn')
    #puts page.body.inspect
  end

 
end
