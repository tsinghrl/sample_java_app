# Use an official OpenJDK image to run the application
FROM openjdk:17-jdk-slim

# Copy the JAR file from the build stage
COPY target/*.jar app.jar

#Expose the application port
EXPOSE 9090

# Set the command to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
