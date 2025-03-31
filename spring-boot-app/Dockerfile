# Use OpenJDK 11 as base image
FROM openjdk:11-jre-slim

# Create a working directory inside the container
WORKDIR /app

# Copy the JAR file from target directory
COPY target/*.jar app.jar

# Expose the port the application runs on (this is the default for Spring Boot)
EXPOSE 8080

# Run the Spring Boot JAR file
ENTRYPOINT ["java", "-jar", "app.jar"]
