PREMAIN_HOME  = /opt/premain-jdk
MAINLINE_HOME = /opt/mainline-jdk

PREMAIN_JAVA  = ${PREMAIN_HOME}/bin/java
MAINLINE_JAVA = ${MAINLINE_HOME}/bin/java

JAR_CMD       = ${MAINLINE_HOME}/bin/jar
APP_JAR       = target/leyden-jmh-1.0-SNAPSHOT-jar-with-dependencies.jar

CLASSLIST     = target/jmh-javac.classlist
STATIC_JSA    = target/jmh-javac.static.jsa
DYNAMIC_JSA   = target/jmh-javac.dynamic.jsa
CACHED_CODE   = target/jmh-javac.code.jsa

NO_CDS_RUN_LOG         = target/runx.log
NO_CDS_RUN_REPORT      = target/runx.report
MAINLINE_RUN_LOG       = target/run21.log
MAINLINE_RUN_REPORT    = target/run21.report
PREMAIN_RUN_LOG        = target/run0.log
PREMAIN_RUN_REPORT     = target/run0.report
STATIC_JSA_RUN_LOG     = target/runs.log
STATIC_JSA_RUN_REPORT  = target/runs.report
DYNAMIC_JSA_RUN_LOG    = target/rund.log
DYNAMIC_JSA_RUN_REPORT = target/rund.report
CACHED_CODE_RUN_LOG    = target/run.log
CACHED_CODE_RUN_REPORT = target/run.report

RUN_ALL_REPORT = target/run-all.report

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

${DYNAMIC_JSA}: ${STATIC_JSA}
	echo Creating dynamic archive
	rm -f ${DYNAMIC_JSA} ${DYNAMIC_JSA}.log
	${PREMAIN_JAVA} -XX:SharedArchiveFile=${STATIC_JSA} -XX:ArchiveClassesAtExit=${DYNAMIC_JSA} \
	    -Xlog:cds=debug,cds+class=debug,cds+resolve=debug:file=${DYNAMIC_JSA}.log \
	    -XX:+RecordTraining -jar ${APP_JAR}

${CACHED_CODE}: ${DYNAMIC_JSA}
	echo Generating AOT code
	rm -f ${CACHED_CODE}
	${PREMAIN_JAVA} -XX:SharedArchiveFile=${DYNAMIC_JSA} -XX:+ReplayTraining -XX:+StoreCachedCode \
	     -XX:CachedCodeFile=${CACHED_CODE} -XX:CachedCodeMaxSize=512M -jar ${APP_JAR}


# run with premain optimization
run: ${CACHED_CODE}
	echo Running with AOT code
	rm -f ${CACHED_CODE_RUN_LOG} ${CACHED_CODE_RUN_REPORT}
	${PREMAIN_JAVA} -XX:SharedArchiveFile=${DYNAMIC_JSA} -XX:+ReplayTraining -XX:+LoadCachedCode \
		-XX:CachedCodeFile=${CACHED_CODE} -Xlog:scc=error -jar ${APP_JAR} > ${CACHED_CODE_RUN_LOG}
	echo "Running with AOT code" >> ${CACHED_CODE_RUN_REPORT}
	grep Iteration ${CACHED_CODE_RUN_LOG} >> ${CACHED_CODE_RUN_REPORT}

# run with static CDS archive
runs: ${STATIC_JSA}
	echo Running with static archive
	rm -f ${STATIC_JSA_RUN_LOG} ${STATIC_JSA_RUN_REPORT}
	${PREMAIN_JAVA} -XX:SharedArchiveFile=${STATIC_JSA} -jar ${APP_JAR} > ${STATIC_JSA_RUN_LOG}
	echo "Running with static archive" >> ${STATIC_JSA_RUN_REPORT}
	grep Iteration ${STATIC_JSA_RUN_LOG} >> ${STATIC_JSA_RUN_REPORT}

# run with dynamic CDS archive
rund: ${DYNAMIC_JSA}
	echo Running with dynamic archive
	rm -f ${DYNAMIC_JSA_RUN_LOG} ${DYNAMIC_JSA_RUN_REPORT}
	${PREMAIN_JAVA} -XX:SharedArchiveFile=${DYNAMIC_JSA} -jar ${APP_JAR} > ${DYNAMIC_JSA_RUN_LOG}
	echo "Running with dynamic archive" >> ${DYNAMIC_JSA_RUN_REPORT}
	grep Iteration ${DYNAMIC_JSA_RUN_LOG} >> ${DYNAMIC_JSA_RUN_REPORT}

# run with default CDS archive (no premain optimization)
run0: ${APP_JAR}
	echo Running with premain JDK WITHOUT optimizations
	rm -f ${PREMAIN_RUN_LOG} ${PREMAIN_RUN_REPORT}
	${PREMAIN_JAVA} -jar ${APP_JAR} > ${PREMAIN_RUN_LOG}
	echo "Running with premain JDK WITHOUT optimizations" >> ${PREMAIN_RUN_REPORT}
	grep Iteration ${PREMAIN_RUN_LOG} >> ${PREMAIN_RUN_REPORT}

# run with CDS turned off
runx: ${APP_JAR}
	echo Running with CDS turned off
	rm -f ${NO_CDS_RUN_LOG} ${NO_CDS_RUN_REPORT}
	${PREMAIN_JAVA} -Xshare:off -jar ${APP_JAR} > ${NO_CDS_RUN_LOG}
	echo "Running with CDS turned off" >> ${NO_CDS_RUN_REPORT}
	grep Iteration ${NO_CDS_RUN_LOG} >> ${NO_CDS_RUN_REPORT}

run21: ${APP_JAR}
	echo Running with mainline JDK WITHOUT optimizations
	rm -f ${MAINLINE_RUN_LOG} ${MAINLINE_RUN_REPORT}
	${MAINLINE_JAVA} -jar ${APP_JAR} > ${MAINLINE_RUN_LOG}
	echo "Running with mainline JDK WITHOUT optimizations" >> ${MAINLINE_RUN_REPORT}
	grep Iteration ${MAINLINE_RUN_LOG} >> ${MAINLINE_RUN_REPORT}

clean:
	rm -rf target

app: ${APP_JAR}

list: ${CLASSLIST}
static: ${STATIC_JSA}
dynamic: ${DYNAMIC_JSA}
aot: ${CACHED_CODE}

all: app aot

runAll: runx run0 runs rund run
	rm -f ${RUN_ALL_REPORT}

	cat ${NO_CDS_RUN_REPORT} >> ${RUN_ALL_REPORT}
	echo "" >> ${RUN_ALL_REPORT}

	cat ${PREMAIN_RUN_REPORT} >> ${RUN_ALL_REPORT}
	echo "" >> ${RUN_ALL_REPORT}

	cat ${STATIC_JSA_RUN_REPORT} >> ${RUN_ALL_REPORT}
	echo "" >> ${RUN_ALL_REPORT}

	cat ${DYNAMIC_JSA_RUN_REPORT} >> ${RUN_ALL_REPORT}
	echo "" >> ${RUN_ALL_REPORT}

	cat ${CACHED_CODE_RUN_REPORT} >> ${RUN_ALL_REPORT}
	echo "" >> ${RUN_ALL_REPORT}