FROM tomcat:8-jdk11-slim

LABEL maintainer="Juho Inkinen <juho.inkinen@helsinki.fi>"

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		wget \
		libvoikko1 \
		voikko-fi \
	## Clean up:
	&& rm -rf /var/lib/apt/lists/* /usr/include/*


# TODO Switch to Maven Central when available there, or build in own stage:
RUN wget https://oss.sonatype.org/service/local/repositories/releases/content/fi/nationallibrary/mauiserver/1.3.2/mauiserver-1.3.2.war \
		-O /usr/local/tomcat/webapps/mauiserver.war -q

RUN mkdir -p /usr/local/tomcat/mauiserver/data
WORKDIR /usr/local/tomcat/mauiserver
