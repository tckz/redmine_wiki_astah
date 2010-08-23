@echo off

set ASTAH_HOME=C:\Program Files\astah-professional

set INITIAL_HEAP_SIZE=16m
set MAXIMUM_HEAP_SIZE=384m

set JAVA_OPTS=-Xms%INITIAL_HEAP_SIZE% -Xmx%MAXIMUM_HEAP_SIZE%

java %JAVA_OPTS% -cp "%ASTAH_HOME%\astah-pro.jar" com.change_vision.jude.cmdline.JudeCommandRunner %*
