FROM centos:centos7

ARG SBT_VERSION=1.3.0
ARG SCALA_VERSION=2.13

ENV SBT_VERSION=${SBT_VERSION}
ENV SCALA_VERSION=${SCALA_VERSION}

ENV SBT_S2I_BUILDER_VERSION=0.1
ENV IVY_DIR=/opt/app-root/src/.ivy2
ENV SBT_DIR=/opt/app-root/src/.sbt
ENV S2I_HOME=/usr/libexec/s2i

LABEL io.k8s.display-name="sbt-s2i $SBT_S2I_BUILDER_VERSION" \
      io.k8s.description="S2I Builder with cached SBT $SBT_VERSION and Scala $SCALA_VERSION" \
      io.openshift.expose-services="9000:http" \
      io.openshift.tags="builder,sbt,scala" \
      io.openshift.min-memory="1Gi" \
      io.openshift.s2i.scripts-url="image://${S2I_HOME}"

USER root

RUN INSTALL_PKGS="git nano curl net-tools tar unzip which lsof java-11-openjdk-devel sbt-$SBT_VERSION" \
 && curl -s https://bintray.com/sbt/rpm/rpm > bintray-sbt-rpm.repo \
 && mv bintray-sbt-rpm.repo /etc/yum.repos.d/ \
 && yum install -y --enablerepo=centosplus $INSTALL_PKGS \
 && rpm -V $INSTALL_PKGS \
 && yum clean all -y

COPY plugins.sbt /tmp

RUN mkdir -p /tmp/caching/project /opt/app-root/bin \
 && cd /tmp/caching \
 && echo "sbt.version = $SBT_VERSION" > project/build.properties \
 && echo "scalaVersion := \"$SCALA_VERSION\"" > build.sbt \
 && mv /tmp/plugins.sbt project \
 && sbt -v -sbt-dir $SBT_DIR -sbt-boot $SBT_DIR/boot -ivy $IVY_DIR compile \
 && chown -R 1001:0 /opt/app-root \
 && chmod -R g+rw /opt/app-root \
 && rm -rf /tmp/* \
 && mkdir -p ${S2I_HOME} \
 && chown -R 1001:0 ${S2I_HOME} \ 
 && chmod -R g+rw ${S2I_HOME}

COPY ./s2i/bin/ ${S2I_HOME}

USER 1001
EXPOSE 9000

CMD ["/usr/libexec/s2i/usage"]
