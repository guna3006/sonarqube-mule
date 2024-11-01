#!/bin/bash

# Constants
VERSION_MAJOR=5
VERSION_MINOR=0
EXTENSION_DIR="./plugins"
COMPOSE_FILE="docker-compose.yaml"
MULE_PLUGIN_FOLDER="mule-sonarqube-plugin"

# Plugin URLs
PLUGIN_URLS=(
  #"https://github.com/SonarQubeCommunity/sonar-scm-cvs/releases/download/1.1.1/sonar-scm-cvs-plugin-1.1.1.jar"
  #"https://github.com/dependency-check/dependency-check-sonar-plugin/releases/download/5.0.0/sonar-dependency-check-plugin-5.0.0.jar"
  #"https://github.com/42Crunch/sonarqube-plugin-releases/releases/download/v2.0.1/sonar-42crunch-plugin-2.0.1.jar"
  #"https://github.com/OtherDevOpsGene/zap-sonar-plugin/releases/download/sonar-zap-plugin-2.3.0/sonar-zap-plugin-2.3.0.jar"
)

# Fetch the latest SonarQube Community Edition version tag
SONAR_VERSION=$(curl -s 'https://hub.docker.com/v2/repositories/library/sonarqube/tags/?page_size=100' | \
jq -r '.results[].name' | \
grep 'community' | \
sort -V | \
tail -n 1)

# Fetch the latest Postgres version tag
POSTGRES_VERSION=$(curl -s 'https://hub.docker.com/v2/repositories/library/postgres/tags/?page_size=100' | \
  jq -r '.results[].name' | \
  grep -E '^[0-9]+\.[0-9]+$' | \
  sort -V | \
  tail -n 1)



# Create the plugins directory
initialize_plugin_directory() {
  echo "Creating plugin directory: $EXTENSION_DIR..."
  mkdir -p "$EXTENSION_DIR"
}

# Download or update plugin based on latest release tag
download_plugin() {
  local url=$1
  local filename
  filename=$(basename "$url")
  local repo
  repo=$(echo "$url" | grep -oP 'github.com/\K[^/]+/[^/]+')

  echo "Checking for the latest version of $repo..."

  # Fetch latest version tag
  local latest_version
  latest_version=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')

  if [ -z "$latest_version" ]; then
    echo "Latest version not found. Downloading specified version for $filename."
    curl -L "$url" -o "$EXTENSION_DIR/$filename"
  else
    local latest_url
    latest_url=$(echo "$url" | sed -E "s/[0-9]+\.[0-9]+\.[0-9]+/$latest_version/")
    echo "Downloading latest version: $latest_url..."
    curl -L "$latest_url" -o "$EXTENSION_DIR/$filename"
  fi

  # Confirm download
  if [ -f "$EXTENSION_DIR/$filename" ]; then
    echo "Saved $filename to $EXTENSION_DIR."
  else
    echo "Error: Failed to download $filename."
  fi
  echo "---------------------------------"
}

# Loop through plugins and update if needed
update_plugins() {
  for url in "${PLUGIN_URLS[@]}"; do
    download_plugin "$url"
  done
}

# Build mule-sonarqube-plugin using Maven
build_mule_plugin() {
  echo "Building the mule-sonarqube-plugin..."
  cd "$MULE_PLUGIN_FOLDER" || exit 1
  mvn clean package sonar-packaging:sonar-plugin -Dlanguage=mule
  local build_status=$?
  cd - || exit 1

  if [ $build_status -ne 0 ]; then
      echo "Maven build failed. Check logs for details."
      exit 1
  fi
  echo "Mule-sonarqube-plugin built successfully."
}

# Copy rules XML files and Mule Validation to the plugin directory
copy_rules_files() {
  echo "Copying rules files to $EXTENSION_DIR..."
  cp "$MULE_PLUGIN_FOLDER/src/test/resources/rules-3.xml" "$EXTENSION_DIR/rules-3.xml"
  cp "$MULE_PLUGIN_FOLDER/src/test/resources/rules-4.xml" "$EXTENSION_DIR/rules-4.xml"
  cp "$MULE_PLUGIN_FOLDER/target/mule-validation-1.0.6.jar" "$EXTENSION_DIR/mule-validation-1.0.6.jar"
}

# Remove the mvn target directory and sonar plugin directory
remove_temp_folder() {
  echo "Removing mvn build folder $MULE_PLUGIN_FOLDER/target..."
  rm -rf "$MULE_PLUGIN_FOLDER/target"
  echo "Removing plugins folder $EXTENSION_DIR..."
  rm -rf "$EXTENSION_DIR"
}

# Update SonarQube Docker image version in the compose file
update_docker_image_version() {
  echo "The latest SonarQube version is: $SONAR_VERSION..."
  echo "Updating SonarQube Docker image in $COMPOSE_FILE to $SONAR_VERSION..."
  sed -i '' 's/image: sonarqube:*.*/image: sonarqube:'$SONAR_VERSION'/' "$COMPOSE_FILE"

  echo "The latest Postgres version is: $POSTGRES_VERSION..."
  echo "Updating Postgres Docker image in $COMPOSE_FILE to $POSTGRES_VERSION..."
  sed -i '' 's/image: postgres:*.*/image: postgres:'$POSTGRES_VERSION'/' "$COMPOSE_FILE"
}

# Start SonarQube container
start_sonarqube() {
  echo "Starting SonarQube container..."
  docker-compose up -d sonarqube

  if [ $? -eq 0 ]; then
    echo "SonarQube started successfully."
  else
    echo "Error: Failed to start SonarQube. Check Docker setup."
  fi
}

# Main function to orchestrate tasks
main() {
  initialize_plugin_directory
  update_plugins
  build_mule_plugin
  copy_rules_files
  update_docker_image_version
  start_sonarqube
  remove_temp_folder
}

# Execute main function
main