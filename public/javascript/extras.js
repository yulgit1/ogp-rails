//not currently being used, since we are using the google geocoder
org.OpenGeoPortal.UserInterface.prototype.geoSearch = function() {
	if (true == true) return;
	jQuery("#geosearch").autocomplete({
		source: function(request, response) {
			jQuery.ajax({
				url: "http://ws.geonames.org/searchJSON",
				dataType: "jsonp",
				data: {
					style: "long",
					maxRows: 12,
					name: request.term
				},
				success: function(data) {
					response(jQuery.map(data.geonames, function(item) {
						var mercatorCoords = map.WGS84ToMercator(item.lng, item.lat);
						return {
							label: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName,
							value: item.name,
							lat: mercatorCoords.lat,
							lon: mercatorCoords.lon
						};
					}));
				}
			});
		},
		minLength: 2,
		delay: 750,
		select: function(event, ui) {
			map.setCenter(new OpenLayers.LonLat(ui.item.lon, ui.item.lat));
			//fire off another ajax request calling google geocoder
		},
		open: function() {
			jQuery(this).removeClass("ui-corner-all").addClass("ui-corner-top");
		},
		close: function() {
			jQuery(this).removeClass("ui-corner-top").addClass("ui-corner-all");
		}
	});
};

//used?
org.OpenGeoPortal.UserInterface.prototype.createQueryString = function(){
	var searchType = this.whichSearch().type;
	if (searchType == 'basicSearch'){
		var searchString = 'searchTerm=' + jQuery('#basicSearchTextField').val();
	    searchString += '&topic=' + jQuery('#selectTopic').val();
	} else if (searchType =='advancedSearch'){
		var searchString = 'keyword=' + jQuery('#advancedKeywordText').val();
		searchString += '&topic=' + jQuery('#advancedSelectTopic').val();
		//searchString += '&collection=' + jQuery('#advancedCollectionText').val();
		searchString += '&publisher=' + jQuery('#advancedPublisherText').val();
		searchString += '&dateFrom=' + jQuery('#advancedDateFromText').val();	
		searchString += '&dateTo=' + jQuery('#advancedDateToText').val();
		searchString += '&typeRaster=' + this.getCheckboxValue('dataTypeCheckRaster');
		searchString += '&typeVector=' + this.getCheckboxValue('dataTypeCheckVector');
		searchString += '&typeMap=' + this.getCheckboxValue('dataTypeCheckMap');
		searchString += '&sourceHarvard=' + this.getCheckboxValue('sourceCheckHarvard');
		searchString += '&sourceMit=' + this.getCheckboxValue('sourceCheckMit');
		searchString += '&sourceMassGis=' + this.getCheckboxValue('sourceCheckMassGis');
		searchString += '&sourcePrinceton=' + this.getCheckboxValue('sourceCheckPrinceton');
		searchString += '&sourceTufts=' + this.getCheckboxValue('sourceCheckTufts');
		searchString += '&sourceStanford=' + this.getCheckboxValue('sourceCheckStanford');
	}	
	if (this.filterState()){
		// pass along the extents of the map
		var extent = map.returnExtent();
		searchString += "&minX=" + extent.minX + "&maxX=" + extent.maxX + "&minY=" + extent.minY + "&maxY=" + extent.maxY; 
	}
	
	return searchString;
};

