PREMAIN_HOME  = /opt/premain-jdk
MAINLINE_HOME = /opt/mainline-jdk

PREMAIN_JAVA  = ${PREMAIN_HOME}/bin/java
MAINLINE_JAVA = ${MAINLINE_HOME}/bin/java

JAR_CMD       = ${MAINLINE_HOME}/bin/jar
APP_JAR       = target/leyden-jmh-1.0-SNAPSHOT-jar-with-dependencies.jar

CLASSLIST     = jmh-javac.classlist
STATIC_JSA    = jmh-javac.static.jsa
DYNAMIC_JSA   = jmh-javac.dynamic.jsa
CACHED_CODE   = jmh-javac.code.jsa

${APP_JAR}:
	mvn package

${CLASSLIST}: ${APP_JAR}
	echo Dumping class list
	${PREMAIN_JAVA} -Xshare:off -XX:DumpLoadedClassList=${CLASSLIST} -jar ${APP_JAR}

${STATIC_JSA}: ${CLASSLIST}
	echo Creating static archive
	rm -f ${STATIC_JSA} ${STATIC_JSA}.log
	${PREMAIN_JAVA} -Xshare:dump -XX:SharedArchiveFile=${STATIC_JSA} -XX:SharedClassListFile=${CLASSLIST} \
		-XX:+PreloadSharedClasses -XX:+ArchiveInvokeDynamic -cp ${APP_JAR} \
	    -Xlog:cds=debug,cds+class=debug,cds+heap=warning,cds+resolve=debug:file=${STATIC_JSA}.log
#	${PREMAIN_JAVA} -XX:SharedArchiveFile=${STATIC_JSA} -jar ${APP_JAR}

${DYNAMIC_JSA}: ${STATIC_JSA}
	echo Creating dynamic archive
	rm -f ${DYNAMIC_JSA} ${DYNAMIC_JSA}.log
	${PREMAIN_JAVA} -XX:SharedArchiveFile=${STATIC_JSA} -XX:ArchiveClassesAtExit=${DYNAMIC_JSA} \
	    -Xlog:cds=debug,cds+class=debug,cds+resolve=debug:file=${DYNAMIC_JSA}.log \
	    -XX:+RecordTraining -jar ${APP_JAR}

${CACHED_CODE}: ${DYNAMIC_JSA}
	echo Generating AOT code
	${PREMAIN_JAVA} -XX:SharedArchiveFile=${DYNAMIC_JSA} -XX:+ReplayTraining -XX:+StoreCachedCode \
	     -XX:CachedCodeFile=${CACHED_CODE} -XX:CachedCodeMaxSize=512M -jar ${APP_JAR}


# run with premain optimization
run: ${CACHED_CODE}
	echo Running with AOT code
	${PREMAIN_JAVA} -XX:SharedArchiveFile=${DYNAMIC_JSA} -XX:+ReplayTraining -XX:+LoadCachedCode \
		-XX:CachedCodeFile=${CACHED_CODE} -Xlog:init -Xlog:scc=error -jar ${APP_JAR}

# run with just static CDS archive
runs: ${STATIC_JSA}
	echo Running with static archive
	${PREMAIN_JAVA} -XX:SharedArchiveFile=${STATIC_JSA} \
		-Xlog:init -jar ${APP_JAR}

# run with just dynamic CDS archive
rund: ${DYNAMIC_JSA}
	echo Running with dynamic archive
	${PREMAIN_JAVA} -XX:SharedArchiveFile=${DYNAMIC_JSA} \
		-Xlog:init -jar ${APP_JAR}

# run WITHOUT premain optimization
run0: ${APP_JAR}
	echo Running with premain JDK WITHOUT optimizations
	${PREMAIN_JAVA} -Xlog:init -jar ${APP_JAR}

run21: ${APP_JAR}
	echo Running with mainline JDK WITHOUT optimizations
	${MAINLINE_JAVA} -Xlog:init -jar ${APP_JAR}

clean:
	rm -rf target

app: ${APP_JAR}

list: ${CLASSLIST}
static: ${STATIC_JSA}
dynamic: ${DYNAMIC_JSA}
aot: ${CACHED_CODE}

all: app aot

runAll: run runs rund run0 run21