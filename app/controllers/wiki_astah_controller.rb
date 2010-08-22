
class WikiAstahController < ApplicationController
  before_filter :find_wiki, :wiki_authorize

	include	WikiAstahHelper

  def diagram
    @page = @wiki.find_page(params[:page], :project => @project)
    if @page.nil?
      render_404
			return
		end

    if params[:version] && !User.current.allowed_to?(:view_wiki_edits, @project)
      # Redirects user to the current version if he's not allowed to view previous versions
			h = params.clone
			h[:version] = nil
      redirect_to h
      return
    end

    begin
		diagram = @astah.diagram(params[:diagram])
    rescue => e
			RAILS_DEFAULT_LOGGER.error "[wiki_astah]diagram(): #{e}"
      render_404
			return
    end
		render :text => diagram, :layout => false, :content_type => 'image/png'
  end

private 

  def wiki_authorize
  	self.authorize("wiki", "index")
  end

  def find_wiki
    @project = Project.find(params[:id])
    @wiki = @project.wiki
    render_404 unless @wiki

		@astah = Astah.find_by_path(@project, params[:astah])
    render_404 unless @astah
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end



# vim: set ts=2 sw=2 sts=2:

