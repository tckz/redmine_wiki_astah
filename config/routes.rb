RedmineApp::Application.routes.draw do
	match 'projects/:project_id/wiki/:id/astah', :to => 'wiki_astah#diagram'
end

# vim: set ts=2 sw=2 sts=2:

