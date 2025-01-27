FROM quay.io/anshuk6469/openjdk8
EXPOSE 8080
ARG JAR_FILE=target/*.jar
ADD ${JAR_FILE} app.jar
COPY trivy-docker-image-scan.sh .
COPY integration-test.sh .
ENTRYPOINT ["java","-jar","/app.jar"]