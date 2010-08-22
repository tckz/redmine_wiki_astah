require 'digest/sha2'
require	'tempfile'

module WikiAstahHelper
	module	Retriver
		def	self.get_retriever(ast)
			if ast.path =~ /^(public|source):(.*)$/
				klass = eval "WikiAstahHelper::Retriver::#{$1.strip.camelize}"
				klass.new(ast.project, $2.to_s.strip)
			else
				raise "[wiki_astah] Unknown prefix for retriever : #{ast.path}"
			end
		end

		class	Base
			def	initialize(project, path)
				@project = project
				@path = path
			end

			def	retrieve(out)
				raise	"[wiki_astah] #{self.class}.retrieve(): Not implement yet."
			end

		end

		class Public < Base
			include WikiAstahHelper
			def	retrieve(out)
				path_public = File.expand_path(File.join([RAILS_ROOT, 'public']))
				path_src = File.expand_path(File.join([path_public, @path]))
				if self.shallow_path?(path_src, path_public)
					raise "Invalid path: {@path}"
				end

				FileUtils.mkdir_p(File.dirname(out))
				FileUtils.copy_file(path_src, out, true, false)
			end
		end

		class Source < Base
			def	retrieve(out)
				if !@project.repository
					raise I18n.translate(:error_source_project_not_have_repository)
				end

				# regexp from app/helpers/application_helper.rb parse_redmine_links()
				@path =~ %r{^[/\\]*(.*?)(@([0-9a-f]+))?(#(L\d+))?$}
				path, rev, anchor = $1, $3, $5
				path = (path.to_s.split(%r{[/\\]}).select {|p| !p.blank?}).join("/")

				entry = @project.repository.entry(path, rev)	
				if !entry
					raise I18n.translate(:error_source_entry_not_found)
				end

				if entry.is_dir?
					raise I18n.translate(:error_source_is_dir)
				end

				content = @project.repository.cat(path, rev)

				FileUtils.mkdir_p(File.dirname(out))
				File.open(out, "wb") { |io|
					io.write(content)
				}
			end

		end
	end

	class Macro
		def	initialize(view, wiki_content)
			@content = wiki_content

			@view = view
			@view.controller.extend(ExtendWikiControler)
		end

		def	astah_diagram(args)
			begin
				name_diagram = args.pop.to_s.strip
				path_astah = args.pop.to_s.strip
				if name_diagram == "" || path_astah == ""
					raise I18n.translate(:error_too_few_macro_param)
				end

				set_macro_params(args)

				ast = Astah.find_by_path_or_new_astah(@content.project, path_astah)
				if ast.new_record? && !ast.save
					@view.controller.render_macro_error({
						:astah => path_astah,
						:diagram => name_diagram,
						:messages => ast.errors.full_messages
					})
				elsif ast.diagram_exist?(name_diagram)
					@view.controller.render_macro_html({
						:astah => path_astah,
						:diagram => name_diagram,
						:params => @macro_params,
					})
				elsif ast.exported
					# The asta has exported, but specified diagram is not found.
					@view.controller.render_macro_error({
						:astah => path_astah,
						:diagram => name_diagram,
						:messages => I18n.translate(:notice_diagram_not_found)
					})
				else
					mes = [
							I18n.translate(:notice_diagram_not_exported)
					]
					if ast.last_message =~ /^([^,]*),(.*$)/
						mes.push(I18n.translate($1.intern, {:message => $2}))
					end
					@view.controller.render_macro_error({
						:astah => path_astah,
						:diagram => name_diagram,
						:messages => mes
					})
				end
			rescue => e
				# wiki_formatting.rb(about redmine 1.0.0) catch exception and write e.to_s into HTML. so escape message.
				ex = RuntimeError.new(ERB::Util.html_escape(e.message))
				ex.set_backtrace(e.backtrace)
				raise ex
			end
		end

private
		def	set_macro_params(args)
			@macro_params = {
			}

			need_value = {
				:target => true,
				:align => true,
				:width => true,
				:height => true,
			}

			args.each {|a|
				k, v = a.split(/=/, 2).map { |e| e.to_s.strip }
				if k.nil? || k == ""
					next
				end

				sym = k.intern
				if need_value[sym] && (v.nil? || v.to_s == "")
					raise "macro parameter:#{k} needs value"
				end
				@macro_params[sym] = v.nil? ? true : v.to_s
			}
		end
	end

	module ExtendWikiControler
		def	render_macro_error(p)
				render_to_string :template => 'wiki_astah/macro_error', :layout => false, :locals => {:macro => p}
		end

		def	render_macro_html(p)
				render_to_string :template => 'wiki_astah/macro', :layout => false, :locals => {:macro => p}
		end
	end


	def	self.cleanse_path(p)
		if p =~ /^([^:]+)\s*:\s*(.*)$/
			p = "#{$1}:#{$2.strip}"
		end
		p
	end


	def	self.base_tmp_path(ast)
		secret = Setting.plugin_redmine_wiki_astah['secret'].to_s
		hashed = Digest::SHA256.hexdigest(ast.path + secret)
		hashed =~ /^(..)/
		head = $1
		{
			:base => File.join([RAILS_ROOT, 'tmp', 'redmine_wiki_astah', 
				ast.project.id.to_s,
				head,
			]),
			:hash => hashed
		}
	end

	def	self.astah_path(ast)
		ret = base_tmp_path(ast)
		ext = File.extname(ast.path) 
		ext = (ext =~ /^\.(asta|jude)$/ ? ext : ".asta")
		File.join([ret[:base], ret[:hash] + ext])
	end

	def	self.diagram_output_path(ast)
		ret = base_tmp_path(ast)
		ret[:base]
	end

	def	self.diagram_path(ast, name_diagram)
		ret = base_tmp_path(ast)
		File.join([ret[:base], ret[:hash], name_diagram ]) + ".png"
	end

	def	shallow_path?(target, base)
		rel = Pathname.new(File.expand_path(target)).relative_path_from(Pathname.new(File.expand_path(base)))

		if rel.to_s =~ /^\.\.#{File::SEPARATOR}/
			return true
		end

		return false
	end

private 
	def	decide_format(fmt)
		fmt = ALLOWED_FORMAT[fmt.to_s.downcase]
		fmt ||= ALLOWED_FORMAT["png"]

		fmt
	end

end

# vim: set ts=2 sw=2 sts=2:

