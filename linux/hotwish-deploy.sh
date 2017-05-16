#!/bin/bash
###### set config ######
PROJECT_NAME=xxx
SOURCE_DIR=/opt/webapps/$PROJECT_NAME
PROJECT_GIT_HTTP=git@gitlab.com:carl_song/xxx.git
TOMCAT_HOME=/opt/apache-tomcat-7.0.72
TOMCAT_PORT=8080
APP_KEYWORD='java.*tomcat'

###### fetch latest verison from remote dev ######
if [ -d "$SOURCE_DIR" ]; then
    rm -rf $SOURCE_DIR
fi

#git clone -b develop $PROJECT_GIT_HTTP $SOURCE_DIR
git clone $PROJECT_GIT_HTTP $SOURCE_DIR
if [ $? -ne 0 ]; then
        echo "=============[FAIL] fetch [ $PROJECT_NAME ] latest version from remote DEVELOP of GitLab. ============="
        exit 0
fi
echo "=============[SUCCESS] fetch [ $PROJECT_NAME ] latest version. ============="

###### compile and package ######
mvn -f $SOURCE_DIR/pom.xml clean package -Dmaven.test.skip -Ponline
if [ $? -ne 0 ]; then
		echo "=============[FAIL] compile and package. ============="
		exit 0
fi
echo "=============[SUCCESS] compile and package. ============="

###### if running, then kill current process ######
pid=`ps aux | grep $APP_KEYWORD | grep -v grep | awk '{print $2}'`
if [ "$pid" ]; then
        echo "=============[RUNNING] pid:$pid ============="
        echo "=============[shutdown...]============="
        $TOMCAT_HOME/bin/catalina.sh stop

        wating_times=0
        wating=0
        while [ $wating -eq 0 ]; do
                echo "wating..."
                sleep 0.1
                pid=`ps aux | grep $APP_KEYWORD | grep -v grep | awk '{print $2}'`
                let wating_times++
                if [ "$pid" -a $wating_times -le 30 ]; then
                        wating=0
                else
                        wating=1
                fi
        done
fi
pid=`ps aux | grep $APP_KEYWORD | grep -v grep | awk '{print $2}'`
if [ "$pid" ]; then
    echo " =============[force shutdown...] pid:$pid============= "
    kill -9 $pid
    sleep 3s
fi

pid=`ps aux | grep $APP_KEYWORD | grep -v grep | awk '{print $2}'`
if [ "$pid" ]; then
    echo " =============[FAIL] shutdown pid:$pid============= "
    exit 0
else
    echo " =============[SUCCESS] shutdown ============= "
fi

###### replace old version ######
rm -rf $TOMCAT_HOME/webapps/hotwish-web.war
rm -rf $TOMCAT_HOME/webapps/hotwish-web
cp -rf $SOURCE_DIR/adx-web/target/hotwish-web.war $TOMCAT_HOME/webapps/

###### startup ######
$TOMCAT_HOME/bin/catalina.sh start

sleep 1
wating_times=0
wating=0
while [ $wating -eq 0 ]; do
    echo "wating"
    sleep 0.1
    let wating_times++
    return_code=`curl -I -m 1 -o /dev/null -s -w %{http_code} http://127.0.0.1:$TOMCAT_PORT/hotwish-web/health/ok`
    if [ $return_code -ne 200 -a $wating_times -le 100 ]; then
            wating=0
    else
            wating=1
    fi
done
return_code=`curl -I -m 1 -o /dev/null -s -w %{http_code} http://127.0.0.1:$TOMCAT_PORT/hotwish-web/health/ok`
if [ $return_code -eq 200 ]; then
    echo " =============[SUCCESS] startup ============= "
else
    echo " =============[FAIL] startup ============= "
fi
