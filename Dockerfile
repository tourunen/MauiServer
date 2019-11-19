FROM maven:slim as builder

LABEL maintainer="Juho Inkinen <juho.inkinen@helsinki.fi>"


COPY src/ src/
COPY pom.xml .
RUN mvn package


FROM tomcat:8-jdk11-slim

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		libvoikko1 \
		voikko-fi \
		gosu \
	&& rm -rf /var/lib/apt/lists/* /usr/include/*

COPY --from=builder /target/mauiserver-*-SNAPSHOT.war /usr/local/tomcat/webapps/mauiserver.war

COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

VOLUME /mauidata
ENV MAUI_SERVER_DATA_DIR=/mauidata

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["catalina.sh", "run"]
