#!/bin/sh

ASTAH_HOME=/usr/lib/astah_professional
#DISPLAY=127.0.0.1:2
#export DISPLAY

INITIAL_HEAP_SIZE=64m
MAXIMUM_HEAP_SIZE=1024m
STACK_SIZE=3m

JAVA_OPTS="-Xms$INITIAL_HEAP_SIZE -Xmx$MAXIMUM_HEAP_SIZE -Xss$STACK_SIZE"

java $JAVA_OPTS -cp "$ASTAH_HOME/astah-pro.jar" com.change_vision.jude.cmdline.JudeCommandRunner "$@"

