FROM tomcat:8-jdk11-slim

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		wget \
	## Voikko:
		libvoikko1 \
		voikko-fi \
	## Clean up:
	&& rm -rf /var/lib/apt/lists/* /usr/include/*


RUN mkdir /srv/maui/ \
	&& wget https://search.maven.org/remotecontent?filepath=fi/nationallibrary/maui/1.4.5/maui-1.4.5-jar-with-dependencies.jar \
		-O /srv/maui/maui-1.4.5-jar-with-dependencies.jar -q \
 	# TODO Switch to Maven Central when available there:
	&& wget https://oss.sonatype.org/service/local/repositories/releases/content/fi/nationallibrary/mauiserver/1.3.2/mauiserver-1.3.2.war \
		-O /usr/local/tomcat/webapps/mauiserver.war -q

RUN mkdir -p /usr/local/tomcat/mauiserver/data
WORKDIR /usr/local/tomcat/mauiserver
