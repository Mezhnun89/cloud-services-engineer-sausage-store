FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /src
COPY pom.xml ./
COPY src ./src
ARG VERSION=1.0.0
RUN mvn -B package -Drevision=${VERSION} && cp target/sausage-store-${VERSION}.jar /app.jar
FROM eclipse-temurin:17-jre-alpine
RUN addgroup -S app && adduser -S -G app -u 10001 app
WORKDIR /app
COPY --from=builder --chown=10001:10001 /app.jar ./app.jar
USER 10001
EXPOSE 8080
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=65.0 -XX:+ExitOnOutOfMemoryError"
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
