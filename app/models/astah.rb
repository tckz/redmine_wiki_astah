require 'digest/sha2'

class Astah < ActiveRecord::Base

	include WikiAstahHelper

  belongs_to :project

  validates_format_of :path, :with => /^(public|source):/

	def	self.find_by_path(project, path)
    find(:first, :conditions => {
			:path => WikiAstahHelper.cleanse_path(path), 
			:project_id => project.id
		})
	end

	def	self.find_by_path_or_new_astah(project, path)
    find_by_path(project, path) || Astah.create(:path => path, :project_id => project.id)
	end

	def	self.export_diagrams
		RAILS_DEFAULT_LOGGER.error "[wiki_astah]export_diagrams: begin"

    find(:all).each { |a|

			phase = nil
			path_astah = WikiAstahHelper.astah_path(a)
			begin
				phase = "error_retrieve"
				a.retrieve(path_astah)

				phase = "error_export"
				a.export_diagram()

			rescue => e
				a.last_message = "#{phase},#{e}"
				RAILS_DEFAULT_LOGGER.error "[wiki_astah]Failed to export diagram for pj=#{a.project.id}, ast=#{a.path}: #{e}"
			end

			a.save

		}

		RAILS_DEFAULT_LOGGER.error "[wiki_astah]export_diagrams: end"
	end

	def	export_diagram
		path_out = WikiAstahHelper.diagram_output_path(self)
		path_astah = WikiAstahHelper.astah_path(self)
		hash_astah = Digest::SHA256.file(path_astah).to_s

		ext = File.extname(path_astah)
		path_export_root = path_astah.slice(0, path_astah.size - ext.size)

		if File.exist?(path_export_root)
			if self.last_hash == hash_astah
				RAILS_DEFAULT_LOGGER.info("[wiki_astah]Skip to export image for pj=#{self.project.id}, ast=#{self.path}")
				return
			end
		end

		RAILS_DEFAULT_LOGGER.info("[wiki_astah]Exporting image for pj=#{self.project.id}, ast=#{self.path}")
		if Redmine::Platform.mswin?
			cmd_run = "run-astah.bat"
		else
			cmd_run = File.join([File.dirname(__FILE__), "..", "..", "run-astah.sh"])
		end
		cmd = "#{cmd_run} -image all -f \"#{path_astah}\" -t png -o \"#{path_out}\""
		RAILS_DEFAULT_LOGGER.info("[wiki_astah]#{cmd}")
		system(cmd)
		RAILS_DEFAULT_LOGGER.info("[wiki_astah]Export image exit: #{$?.inspect}")

		if !($?.exited? && $?.exitstatus == 0)
			raise I18n.translate(:error_export_run, {:status => $?.inspect})
		end

		self.exported = Time.now
		self.last_hash = hash_astah
		self.last_message = ""
	end

	def	retrieve(out)
		retriever = WikiAstahHelper::Retriver.get_retriever(self)
		retriever.retrieve(out)
		self.retrieved = Time.now
		self.last_message = ""
	end

	def	diagram_exist?(name_diagram)
		base = WikiAstahHelper.base_tmp_path(self)
		path = WikiAstahHelper.diagram_path(self, name_diagram)
		if self.shallow_path?(path, base[:base])
			return	false
		end
		File.exist?(path)
	end

	def	diagram(name_diagram)
		base = WikiAstahHelper.base_tmp_path(self)
		path = WikiAstahHelper.diagram_path(self, name_diagram)
		if self.shallow_path?(path, base[:base])
			RAILS_DEFAULT_LOGGER.error "[wiki_astah]Too shallow path: #{name_diagram}"
			raise "Too shallow path."
		end

		File.open(path, "rb") { |f|
			f.read
		}
	end

	def	path=(p)
		write_attribute(:path, WikiAstahHelper.cleanse_path(p))
	end
end

# vim: set ts=2 sw=2 sts=2:

