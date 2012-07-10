# require 'net/http'
require 'nokogiri'

class CatalogController < ApplicationController
  
  def index
  end

  # Assemble ogpConfig.json configuration response needed by the UI
  def get_ogp_config
    respond_to do |format| 
      format.json {
        render :json => OgpRails::Application.config.ogpConfig
      }
    end
  end

  # Serve FGDC geospatial descriptive metadata XML as a file named as the id of the layer (layer_id)
  def get_metadata
    layer_id = params['id']
    download = params['download']
    layer_id
    respond_to do |format|
      format.xml { 
        send_data download_metadata(layer_id), :filename => "#{layer_id}.fgdc.xml", :type => :xml
      }
      format.html {
        render :text => transform_fgdc_to_html(layer_id)
      }
    end

  end 
 
  # This shortens a URL provided by the UI using the Google's (goo.gl) URL shortener API service.
  # Example: For the URL http://geodata.tufts.edu/openGeoPortalHome.jsp?layer%5B%5D=HARVARD.SDE2.G3201_C82_1884_S8_SHEET1&minX=-264.0234375&minY=-85.051128779807&maxX=264.0234375&maxY=85.051128779807
  # The UI will issue a call to this controller as follows:
  # @example
  #   shorten_link /shortenLink?link=http%3A%2F%2Fgeodata.tufts.edu%2FopenGeoPortalHome.jsp%3Flayer%255B%255D%3DHARVARD.SDE2.G3201_C82_1884_S8_SHEET1%26minX%3D-264.0234375%26minY%3D-85.051128779807%26maxX%3D264.0234375%26maxY%3D85.051128779807 
  #   => {"shortLink":"http://goo.gl/GJ5Gn"}

  def shorten_link 
    slink = { :shortLink => Googl.shorten(params['link']).short_url }

    respond_to do |format| 
      format.any {
        render :json => slink
      }
    end
  end

  # Retrieve FGDC geospatial descriptive metadata XML stream
  def download_metadata layer_id

    # TODO: Get XML directly from GeoMDTK and not from 
    # Solr. The FGDC metadata field ("FgdcText") should be indexed but not 
    # stored as the original schema provided by OGP
    #response = Net::HTTP.get_response(URI.parse("#{GEOMDTK_URL}/xml.get.metadata?id=:#{layer_id}")).body

    solr = RSolr.connect :url => OgpRails::Application.config.solr_url

    response = solr.get 'select', :params => {
      :q => "LayerId:#{layer_id}",
      :fl => "LayerId,FgdcText"
    }
    response['response']['docs'].first['FgdcText']
  end

  # Use ESRI's classic FGDC to HTML stylesheet
  def transform_fgdc_to_html layer_id
    fgdc = download_metadata layer_id
    xslt = Nokogiri::XSLT(File.new(File.expand_path(File.dirname(__FILE__)  + '../../resources/xsl/FGDC_Classic_for_Web_body.xsl')))
    xslt.transform(Nokogiri::XML(fgdc))
  end
  
  # WARNING: This must not be used in production. We will 
  # use Apache as a reversed-proxy to http://ogpsolr-prod.stanford.edu:8983/solr/ 
  # in the box this app is deployed.
  def solr_select
    solr_params = {
      :q => params['q'],
      :fq => params['fq'], # Multiple fq key value pairs get collapsed to one by Rails creating wrong resultsets from Solr
      :fl => params['fl'],
      :start => params['start'],
      :rows => params['rows'],
      :sort => params['sort'],
      :wt => 'json',
      :"json.wrf" => params['json.wrf'],
      :"_" => params['_'] 
    } 
    solr = RSolr.connect :url => OgpRails::Application.config.solr_url
    solr_response = solr.get 'select', :params => solr_params

    respond_to do |format| 
      format.html {
        render :json => solr_response
      }
    end
  end

end
