#FROM java:8-jre
FROM shippableimages/ubuntu1404_base:latest
#docker.io/ansible/ubuntu14.04-ansible
MAINTAINER trojanwarrior

# Set required environment vars
ENV PDI_RELEASE=8.3 \
    PDI_VERSION=8.3.0.0-371 \
    CARTE_PORT=8181 \
    PENTAHO_JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    PENTAHO_HOME=/home/pentaho \
    PENTAHO_GIT_HOME=/home/pentaho/GIT

# Create user
RUN mkdir ${PENTAHO_HOME} && \
    groupadd -r pentaho && \
    useradd -s /bin/bash -d ${PENTAHO_HOME} -r -g pentaho pentaho && \
    echo "pentaho:pentaho" | chpasswd && adduser pentaho sudo && \
    chown pentaho:pentaho ${PENTAHO_HOME}

# Add files
RUN mkdir $PENTAHO_HOME/docker-entrypoint.d $PENTAHO_HOME/templates $PENTAHO_HOME/scripts $PENTAHO_GIT_HOME

COPY carte-*.config.xml $PENTAHO_HOME/templates/

COPY docker-entrypoint.sh $PENTAHO_HOME/scripts/

COPY pdi-ce-${PDI_VERSION}.zip /tmp/pdi-ce-${PDI_VERSION}.zip

RUN chown -R pentaho:pentaho $PENTAHO_HOME 
RUN chown pentaho:pentaho /tmp/pdi-ce-${PDI_VERSION}.zip
RUN chmod +x $PENTAHO_HOME/scripts/docker-entrypoint.sh 
RUN add-apt-repository ppa:openjdk-r/ppa
RUN apt-get update
RUN apt-get install -y unzip openjdk-8-jdk x11-apps libwebkitgtk-1.0-0
RUN ldconfig
#RUN apt-get install xeyes

# Switch to the pentaho user
USER pentaho

# Download PDI
# http://downloads.sourceforge.net/project/pentaho/Data%20Integration/${PDI_RELEASE}/pdi-ce-${PDI_VERSION}.zip \
#RUN /usr/bin/wget \
#    --progress=dot:giga \
#    https://sourceforge.net/projects/pentaho/files/latest/download \
#    -O /tmp/pdi-ce-${PDI_VERSION}.zip && \

RUN sh -c '/usr/bin/unzip -q /tmp/pdi-ce-${PDI_VERSION}.zip -d  $PENTAHO_HOME && rm /tmp/pdi-ce-${PDI_VERSION}.zip'

# We can only add KETTLE_HOME to the PATH variable now
# as the path gets eveluated - so it must already exist
ENV KETTLE_HOME=$PENTAHO_HOME/data-integration \
    PATH=$KETTLE_HOME:$PATH

# Expose Carte Server
EXPOSE ${CARTE_PORT}

# As we cannot use env variable with the entrypoint and cmd instructions
# we set the working directory here to a convenient location
# We set it to KETTLE_HOME so we can start carte easily
WORKDIR $KETTLE_HOME


ENTRYPOINT ["../scripts/docker-entrypoint.sh"]

# Run Carte - these parameters are passed to the entrypoint
#CMD ["carte.sh", "carte.config.xml"]
CMD ["spoon.sh"]
