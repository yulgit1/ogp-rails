class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  #include SulChrome::Controller

  #def layout_name
  # 'sul_chrome/application'
  #end

  helper_method :is_production?

  helper_method :current_user
  helper_method :destroy_user_session_path

  # used to determine if we should show beta message in UI
  def is_production?
    return true if Rails.env.production? and (!request.env["HTTP_HOST"].nil? and !request.env["HTTP_HOST"].include?("-test") and !request.env["HTTP_HOST"].include?("-dev") and !request.env["HTTP_HOST"].include?("localhost"))
  end

  def current_user
    'renzo'
  end

  def destroy_user_session_path
    true
  end
  
  def solr_select
    # http://ogpsolr-dev.stanford.edu:8983/solr/select?q=_val_:%22product(10.0,map(sum(map(MinX,-180,180,1,0),map(MaxX,-180,180,1,0),map(MinY,-85.513398309887,84.541361073134,1,0),map(MaxY,-85.513398309887,84.541361073134,1,0)),4,4,1,0)))%22_val_:%22product(15.0,recip(sum(abs(sub(Area,61219.713377887565)),.01),1,1000,1000))%22_val_:%22product(3.0,recip(abs(sub(product(sum(MaxX,MinX),.5),0)),1,1000,1000))%22_val_:%22product(3.0,recip(abs(sub(product(sum(MaxY,MinY),.5),-0.48601861837649807)),1,1000,1000))%22&&fq={!frange+l%3D1+u%3D10}product(2.0,map(sum(map(sub(abs(sub(0,CenterX)),sum(180,HalfWidth)),0,400000,1,0),map(sub(abs(sub(-0.48601861837649807,CenterY)),sum(85.0273796915105,HalfHeight)),0,400000,1,0)),0,0,1,0))&wt=json&fl=Name,CollectionId,Institution,Access,DataType,Availability,LayerDisplayName,Publisher,GeoReferenced,Originator,Location,MinX,MaxX,MinY,MaxY,ContentDate,LayerId,score,WorkspaceName,SrsProjectionCode&rows=24&start=0&sort=score+desc&fq=Institution%3ATufts+OR+Institution%3AHarvard+OR+Institution%3ABerkeley+OR+Institution%3AMIT+OR+Institution%3AMassGIS+OR+Institution%3APrinceton+OR+Institution%3AStanford&fq=Institution:Stanford+OR+Access:Public&json.wrf=jQuery16406787558083888143_1339107460557&_=1339108598448

  end
  
  protect_from_forgery
end
