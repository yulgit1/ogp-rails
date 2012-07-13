require 'net/http'
require 'nokogiri'
require 'rgeoserver'
require 'open-uri'
require 'zip/zip'
require 'zip/zipfilesystem'
require 'tempfile'

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
    fgdc = get_layer(layer_id)['FgdcText']
    respond_to do |format|
      format.xml { 
        send_data fgdc, :filename => "#{layer_id}.fgdc.xml", :type => :xml
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
  #   /shortenLink?link=http%3A%2F%2Fgeodata.tufts.edu%2FopenGeoPortalHome.jsp%3Flayer%255B%255D%3DHARVARD.SDE2.G3201_C82_1884_S8_SHEET1%26minX%3D-264.0234375%26minY%3D-85.051128779807%26maxX%3D264.0234375%26maxY%3D85.051128779807 
  #   => {"shortLink":"http://goo.gl/GJ5Gn"}
  # TODO: Filter here only OGP Consortium domains to avoid potential abuse of this proxied service.
  def shorten_link 
    slink = { :shortLink => Googl.shorten(params['link']).short_url }
    respond_to do |format| 
      format.any {
        render :json => slink
      }
    end
  end

  # Retrieves layer document from solr
  # Refer to app/resources/solr/schema.xml for additional information of all 
  # available fields
  def get_layer layer_id
    solr = RSolr.connect :url => OgpRails::Application.config.solr_url
    response = solr.get 'select', :params => {:q => "LayerId:#{layer_id}" }
    response['response']['docs'].first
  end

  # Use ESRI's classic FGDC to HTML stylesheet
  def transform_fgdc_to_html layer_id
    fgdc = get_layer(layer_id)['FgdcText']
    xslt = Nokogiri::XSLT(File.new(File.expand_path(File.dirname(__FILE__)  + '../../resources/xsl/FGDC_Classic_for_Web_body.xsl')))
    xslt.transform(Nokogiri::XML(fgdc))
  end

  def feature_info
    if params['format'] == 'html'
      format = 'text/html'
    else
      format = 'application/vnd.ogc.gml'
    end

    width = params['width']
    height = params['height']
    bbox = params['bbox']
    x = params['x']
    y = params['y']
    layer_id = params['OGPID']

    layer = get_layer layer_id
    layer_name = "#{layer['WorkspaceName']}:#{layer['Name']}"
    institution = layer['Institution']
    conf = OgpRails::Application.config.ogpConfig[:config]
    institution_config = conf['institutions'][institution]

    if institution_config.has_key?('proxy') 
      # ignore access level for now
      access_level = institution_config['proxy']['access_level']
      wms_url = institution_config['proxy']['wms']
      feature_info_url = "#{wms_url}?service=wms&version=1.1.1&request=GetFeatureInfo&info_format=#{format}&SRS=EPSG:900913&feature_count=1&styles=&height=#{height}&width=#{width}&bbox=#{bbox}&x=#{x}&y=#{y}&query_layers=#{layer_name}&layers=#{layer_name}"
      response = begin 
        Net::HTTP.get_response(URI.parse(feature_info_url)).body    
      rescue
        "There was an remote error retrieving the feature information"
      end
    else
      response = "This layer contains no feature information available"
    end
  
    respond_to do |format| 
      format.any {
        render :text => response
      }
    end
  end
  
  def download
    # Sample call contains the following parameters:
    # bbox:-123.96368102435,36.400754646088,-120.48650817279,39.348557017673
    # layers: bg073np4693=shp
    # layerNumber:1
    # We assume the 'layers' parameter contains only one layer, therefore layerNumber = 1. 
    # We will not handle multi-downloads.
    # We are not handling feature cropping at the moment, therefore params['bbox'] is ignored.
    # Possible formats: 
    # For vector:
    # shp = ESRI Shapefile
    # kmz = Compressed Keyhole Markup Language
    # For raster:
    # GeoTIFF = GeoTIFF
    # kmz = Compressed Keyhole Markup Language
    layer_id, format = params['layers'].split('=')
    if format == 'shp'
      format_ext = 'shp'
    elsif format == 'GeoTIFF'
      format_ext = 'tif'
    else
      format_ext = 'kmz'
    end

    layer = get_layer layer_id
    workspace_name = layer['WorkspaceName']
    institution = layer['Institution']
    conf = OgpRails::Application.config.ogpConfig[:config]
    institution_config = conf['institutions'][institution]

    if institution_config.has_key?('proxy') && workspace_name == 'stanford'
      # Obtain GeoServer's admin access information
      gs_url = institution_config['proxy']['admin_url']
      gs_user = institution_config['proxy']['admin_user']
      gs_pass = institution_config['proxy']['admin_pass']

      geoserver = RGeoServer::Catalog.new :url => gs_url, :user => gs_user, :password => gs_pass 
      gs_workspace = RGeoServer::Workspace.new geoserver, :name=> 'stanford'  
      gs_layer = geoserver.get_layer(layer_id)
      # GeoServer layer types can be 'VECTOR' or 'RASTER' (or 'WMS' but this will not be handled)
      layer_type = gs_layer.profile['type']
      # Resource can be a RGeoServer::FeatureType if Vector or Coverage if Raster which in turn implies 
      # that the underlying data store is either a RGeoServer::DataStore or RGeoServer::CoverageStore, respectively.
      resource = gs_layer.resource
      if layer_type == 'VECTOR'
        # Path should be of the form: "file:///geo/staging/branner/Precincts_Jan262012_5/Precincts_Jan262012_5.shp
        store = resource.data_store
        path_uri = URI.parse store.connection_parameters['url']
      elsif layer_type == 'RASTER'
        # Path should be of the form: "file:///geo/staging/rumsey/CassiniWorldGlobe1790.tif"
        store = resource.coverage_store
        path_uri = URI.parse store.url 
      else
        raise "Layer type #{layer_type} cannot be processed"
      end

    else
      failed = "This layer contains no data available for download"
    end
  
    download_name = "#{Digest::MD5.hexdigest(layer_id)}.#{format_ext}.zip"
    download_path = File.expand_path(File.dirname(__FILE__)  + "../../../public/download/#{download_name}")
    unless File.exist? download_path
      Zip::ZipFile.open(download_path, Zip::ZipFile::CREATE) do |zipfile| 
        if format_ext == 'shp'
          Dir["#{File.dirname(path_uri.path)}/**/**"].reject{ |f| f == download_name}.each do |file| 
            zipfile.add(file.sub(File.dirname(path_uri.path),'./'), file)
          end
        elsif format_ext == 'tif'
          zipfile.add(File.basename(path_uri.path), path_uri.path)
        end
        # Finally add FGDC metadata file to zip file
        fgdc_file = Tempfile.new(layer_id)  
        fgdc_file.write(layer['FgdcText'])
        zipfile.add("#{layer_id}.fgdc.xml", fgdc_file)
        fgdc_file.close
      end
    end

    respond_to do |format| 
      format.any {
        render :json => {
          "succeeded" => [{ 
            "message" => "The layer was successfully downloaded.",
            "title" => gs_layer.name,
            "layerId" => layer_id,
            "disposition" => "DOWNLOADED_LOCALLY",
            "institution" => institution
          }],
          "failed" => [],
          "packageLink" => "download\/#{download_name}"
        }
      }
    end
  end
  
  def zip_layer layer_id 
    
  end
 
  # WARNING: This must not be used in production. We will 
  # use Apache as a reversed-proxy to http://ogpsolr-prod.stanford.edu:8983/solr/ 
  # in the box this app is deployed.
  def solr_select
    solr_params = {
      :q => params['q'],
      :fq => params['fq'], # Multiple fq key value pairs get collapsed to one by Rails creating wrong result sets from Solr
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
