ActionController::Routing::Routes.draw do |map|

	map.connect 'projects/:id/wiki/:page/astah', :controller => 'wiki_astah', :action => 'diagram'
end

# vim: set ts=2 sw=2 sts=2:
