FROM tomcat:8-jdk11-slim

LABEL maintainer="Juho Inkinen <juho.inkinen@helsinki.fi>"

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		wget \
		libvoikko1 \
		voikko-fi \
		gosu \
	## Clean up:
	&& rm -rf /var/lib/apt/lists/* /usr/include/*


# TODO Switch to Maven Central when available there, or build in own stage:
RUN wget https://oss.sonatype.org/service/local/repositories/releases/content/fi/nationallibrary/mauiserver/1.3.2/mauiserver-1.3.2.war \
	-O /usr/local/tomcat/webapps/mauiserver.war -q


ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["catalina.sh", "run"]
