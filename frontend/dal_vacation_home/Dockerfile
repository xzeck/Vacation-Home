# Use the official Flutter Docker image for building
FROM ghcr.io/cirruslabs/flutter:3.22.2 AS build

# Copy Flutter app files
COPY . /app
WORKDIR /app

# Install dependencies and build Flutter web app
RUN flutter config --enable-web && flutter build web --release

# Use an official Nginx image to serve the built Flutter web app
FROM nginx:alpine

# Copy the build output to the Nginx HTML folder
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose the port that Nginx is running on
EXPOSE 80

# Start Nginx server
CMD ["nginx", "-g", "daemon off;"]
