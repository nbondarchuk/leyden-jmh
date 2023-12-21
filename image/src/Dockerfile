FROM ubuntu:focal

ADD setup.sh /setup.sh
RUN ./setup.sh


FROM ubuntu:focal

RUN export DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y --no-install-recommends make git ca-certificates

COPY --from=0 /opt/maven /opt/maven
COPY --from=0 /opt/premain-jdk /opt/premain-jdk
COPY --from=0 /opt/mainline-jdk /opt/mainline-jdk

ENV M2_HOME /opt/maven
ENV MAVEN_HOME /opt/maven
ENV JAVA_HOME /opt/mainline-jdk
ENV PATH $JAVA_HOME/bin:$M2_HOME/bin:$PATH

RUN mkdir /opt/leyden
VOLUME /opt/leyden

ADD test.sh /test.sh
CMD /test.sh