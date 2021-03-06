require 'digest/sha2'

class Astah < ActiveRecord::Base

	include WikiAstahHelper

  belongs_to :project

	attr_accessible :path, :project_id
  validates_format_of :path, :with => /\A(public|source):/

	def	self.find_by_path(project, path)
    Astah.find_by(
			:path => WikiAstahHelper.cleanse_path(path), 
			:project_id => project.id
		)
	end

	def	self.find_by_path_or_new_astah(project, path)
		Rails::logger.info "[wiki_astah]#{path}"
    find_by_path(project, path) || Astah.create(:path => path, :project_id => project.id)
	end

	def	self.export_diagrams
		Rails::logger.info "[wiki_astah]export_diagrams: begin"

    Astah.all.each { |a|

			phase = nil
			path_astah = WikiAstahHelper.astah_path(a)
			begin
				phase = "error_retrieve"
				a.retrieve(path_astah)

				phase = "error_export"
				a.export_diagram()

			rescue => e
				a.last_message = "#{phase},#{e}"
				Rails::logger.error "[wiki_astah]Failed to export diagram for pj=#{a.project.id}, ast=#{a.path}: #{e}"
			end

			a.save

		}

		Rails::logger.info "[wiki_astah]export_diagrams: end"
	end

	def	export_diagram
		path_out = WikiAstahHelper.diagram_output_path(self)
		path_astah = WikiAstahHelper.astah_path(self)
		hash_astah = Digest::SHA256.file(path_astah).to_s

		ext = File.extname(path_astah)
		path_export_root = path_astah.slice(0, path_astah.size - ext.size)

		if File.exist?(path_export_root)
			if self.last_hash == hash_astah
				Rails::logger.info("[wiki_astah]Skip to export image for pj=#{self.project.id}, ast=#{self.path}")
				return
			end
		end

		Rails::logger.info("[wiki_astah]Exporting image for pj=#{self.project.id}, ast=#{self.path}")
		if Redmine::Platform.mswin?
			cmd_run = "run-astah.bat"
		else
			cmd_run = File.join([File.dirname(__FILE__), "..", "..", "run-astah.sh"])
		end
		cmd = "#{cmd_run} -image all -f \"#{path_astah}\" -t png -o \"#{path_out}\""
		Rails::logger.info("[wiki_astah]#{cmd}")
		system(cmd)
		Rails::logger.info("[wiki_astah]Export image exit: #{$?.inspect}")

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
		if self.shallow_path?(path, File.join(base[:base], base[:hash]))
			return	false
		end
		File.exist?(self.to_local_encoded_path(path))
	end

	def	diagram(name_diagram)
		base = WikiAstahHelper.base_tmp_path(self)
		path = WikiAstahHelper.diagram_path(self, name_diagram)
		if self.shallow_path?(path, File.join(base[:base], base[:hash]))
			Rails::logger.error "[wiki_astah]Too shallow path: #{name_diagram}"
			raise "Too shallow path."
		end

		File.open(self.to_local_encoded_path(path), "rb") { |f|
			f.read
		}
	end

	def	path=(p)
		write_attribute(:path, WikiAstahHelper.cleanse_path(p))
	end
end

# vim: set ts=2 sw=2 sts=2:

