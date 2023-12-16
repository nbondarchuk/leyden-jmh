PREMAIN_HOME  = /opt/premain-jdk
MAINLINE_HOME = /opt/mainline-jdk

PREMAIN_JAVA  = ${PREMAIN_HOME}/bin/java
MAINLINE_JAVA = ${MAINLINE_HOME}/bin/java

JAR_CMD       = ${MAINLINE_HOME}/bin/jar
APP_JAR       = target/leyden-jmh-1.0-SNAPSHOT-jar-with-dependencies.jar

CLASSLIST     = jmh-javac.classlist
STATIC_JSA    = jmh-javac.static.jsa

${APP_JAR}:
	mvn package
	${MAINLINE_JAVA} -jar ${APP_JAR}

${CLASSLIST}: ${APP_JAR}
	echo Dumping loaded class list
	${PREMAIN_JAVA} -Xshare:off -XX:DumpLoadedClassList=${CLASSLIST} -cp ${APP_JAR} -jar ${APP_JAR}

${STATIC_JSA}: ${CLASSLIST}
	echo Creating static archive
	rm -f ${STATIC_JSA}.log
	${PREMAIN_JAVA} -Xshare:dump -XX:SharedArchiveFile=${STATIC_JSA} -XX:SharedClassListFile=${CLASSLIST} \
		-XX:+PreloadSharedClasses -cp ${APP_JAR} \
	    -Xlog:cds=debug,cds+class=debug,cds+heap=warning,cds+resolve=debug:file=${STATIC_JSA}.log

clean:
	rm -rf target

app: ${APP_JAR}

list: ${CLASSLIST}

static: ${STATIC_JSA}

all: app static
