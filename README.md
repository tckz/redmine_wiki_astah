# Redmine Wiki Astah-macro plugin

Redmine Wiki Astah-macro plugin allows Redmine's wiki to embed image of the diagram which is described by astah*  
 http://passing.breeze.cc/mt/archives/2010/08/astah-redmine-wiki-2.html

## Features

* Add wiki macro ```{{astah_diagram}}```
* The plugin makes it link to the image which is exported from .asta file.
* Note: To create embeded image, you must run ```Astah.export_diagrams()``` periodically by some scheduler which like a cron.

### {{astah_diagram}} macro

* Embed image which is exported from the diagram which is described by astah*.

	```
    {{astah_diagram(asta=public:foo.asta, namespace/diagram)}}
    {{astah_diagram(asta=source:/repo/path/foo.asta, namespace/diagram)}}
    {{astah_diagram(option=value...,public:foo.asta, namespace/diagram)}}

    Old format:
    {{astah_diagram(source:/repo/path/foo.asta, namespace/diagram)}}
  	```
  
	Note: .asta file path should be 'public:path/to/asta.asta' or 'source:repositorypath/to/asta.asta'.

	Note: Diagram path follows to astah*'s export function. If your diagram name (or namespace) contains '/', the function convert it to '_'.

	Note: After redmine 1.3.0, The sequence of expanding wiki links is changed. So, 'source:path/to/file.asta' is expanded as HTML link before executing the macro. To avoid link expansion, you should specify it like "asta=source:path/to/file.asta".

* target=value : Additional attribute for IMG.  
   e.g.) ```_blank```
* align=value : Additional attribute for IMG.  
   e.g.) ```right```, ```left```
* width=value : Additional attribute for IMG.   
   e.g.) ```200px```, ```100%```
* height=value : Additional attribute for IMG.   
   e.g.) ```200px```, ```50%```

## Requirement

* Redmine 3.0.0 or later.
* ruby 2.2
* astah* professional 6.6 or later http://astah.change-vision.com/ja/
	* (For linux)
		* Configure the environment able to run JudeCommandRunner.  
       For example. http://passing.breeze.cc/mt/archives/2010/05/astah-redmine-wiki-1.html 

## Getting the plugin

https://github.com/tckz/redmine_wiki_astah

e.g.)

```
git clone git://github.com/tckz/redmine_wiki_astah.git
```

## Install

1. Copy the plugin tree into #{RAILS_ROOT}/plugins/

	```
    #{RAILS_ROOT}/plugins/
        redmine_wiki_astah/
	```
2. Configure variable value in script.
	
	```
    (For linux)Configure variable value in redmine_wiki_astah/run-astah.sh
      ASTAH_HOME : Point the directory where astah-pro.jar is exist.
      DISPLAY    : Point to your display(such as X Server).
                   Recent astah* does not require Dispaly to export diagrams.
                   If you use older astah*, you should setup DISPLAY.
    (For Windows)Configure variable value in redmine_wiki_astah/run-astah.bat
      ASTAH_HOME : Point the directory where astah-pro.jar is exist.
	```
3. ```rake redmine:plugins:migrate RAILS_ENV=production```
4. Restart Redmine.
5. Login to Redmine as an Administrator 
6. Setup wiki astah-macro settings in the Plugin settings panel.

	```
    'secret key' : Specify any random text you like.
	```
7. To create embeded image, you must configure to execute Astah.export_diagrams() periodically.
    
	```
    #{RAILS_ROOT}/bin/rails runner Astah.export_diagrams -e production
	```
    
    Note: Please take care of the user who runs redmine and Astah.export_diagrams.

    Note: If you execute the method on Windows, you must make sure that run-astah.bat on the PATH.
          One easy way to accomplish above, run the .bat like below.
          
	```
@echo off
cd path\to\vendor\plugins\redmine_wiki_astah
path\to\ruby.exe ..\..\..\bin\rails runner Astah.export_diagrams -e production
	```

## License

This plugin is licensed under the GNU GPL v2.  
See COPYRIGHT.txt and GPL.txt for details.

## Known Issues

* ver 0.0.1: If database is MySQL, ```db:migrate:plugins``` fails.  
   Please drop table astahs manually. And download newest version and try to migrate again.

## My environment

* CentOS 6.6 x64
* ruby-2.2.0p0
* MySQL-server-5.6.17-1.el6.x86_64
* redmine-3.0.0
* astah* pro 6.8.0

