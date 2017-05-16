#!/bin/bash
###### set config ######
TOMCAT_HOME=/root/apache-tomcat-8.5.9

###### stop server
$TOMCAT_HOME/bin/shutdown.sh
sleep 3

###### replace old version ######
rm -rf $TOMCAT_HOME/webapps/ROOT.war
rm -rf $TOMCAT_HOME/webapps/ROOT

cp -rf /root/ROOT.war $TOMCAT_HOME/webapps/

###### unzip ######
unzip /root/ROOT.war -d $TOMCAT_HOME/webapps/ROOT/
sleep 3

###### change db config ######
rm -f $TOMCAT_HOME/webapps/ROOT/WEB-INF/classes/config.properties
cp -rf /root/config.properties $TOMCAT_HOME/webapps/ROOT/WEB-INF/classes/config.properties

###### startup ######
$TOMCAT_HOME/bin/startup.sh
sleep 3
