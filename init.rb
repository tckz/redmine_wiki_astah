require 'redmine'

Redmine::Plugin.register :redmine_wiki_astah do
	name 'astah* Wiki-macro plugin'
	author 'tckz'
  description 'Embed image of the diagram which is described by astah*'
	version '0.2.0'
	requires_redmine :version_or_higher => '2.0.0'
  url "http://passing.breeze.cc/mt/" if respond_to?(:url)
	settings :default => {
			"secret" => "specify some random text",
		}, :partial => 'wiki_astah/settings'

	Redmine::WikiFormatting::Macros.register do
		desc <<'EOF'
Embed image which is exported from the diagram which is described by astah*.

  !{{astah_diagram(asta=public:foo.asta, namespace/diagram)}}
  !{{astah_diagram(asta=source:/repo/path/foo.asta, namespace/diagram)}}
  !{{astah_diagram(option=value...,asta=public:foo.asta, namespace/diagram)}}

* options are:
** target={_blank|any}
** align=value(e.g. {right|left})
** width=value(e.g. 100px, 200%)
** height=value(e.g. 100px, 200%)
EOF

		macro :astah_diagram do |wiki_content_obj, args|
			m = WikiAstahHelper::Macro.new(self, wiki_content_obj)
			m.astah_diagram(args)
		end

	end

end


# vim: set ts=2 sw=2 sts=2:

