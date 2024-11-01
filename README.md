# MuleSoft SonarQube Integration

## Project Overview

This project provides a setup for integrating SonarQube with MuleSoft applications to enable code quality analysis, create custom rules, and perform code scanning using the SonarQube platform.

## Contents

- **docker-compose.yaml**: Defines the Docker environment for running SonarQube.
- **RUNME.sh**: A script for initializing or configuring the SonarQube setup.
- **mule-sonarqube-plugin/**: Contains files for configuring and deploying the MuleSoft plugin for SonarQube.
- **pom.xml**: Maven configuration for building the plugin.
- **img/**: Contains images demonstrating configuration and setup steps.

## Prerequisites

- **Docker** and **Docker Compose** installed on your system.
- **Maven** for building the MuleSoft SonarQube plugin.

## Setup Instructions

1. **Start SonarQube**:
   - Run `docker-compose up -d` in the project’s root directory to start the SonarQube service.

2. **Initialize the Environment**:
   - Execute `./RUNME.sh` to configure the SonarQube environment and set up necessary plugins or customizations for MuleSoft.

3. **Build and Deploy the Plugin**:
   - Navigate to `mule-sonarqube-plugin/` and run `mvn clean install` to build the MuleSoft SonarQube plugin.
   - Deploy the plugin to SonarQube by following instructions in the setup images located in the `img/` folder.

## Usage

Once setup, SonarQube can scan and analyze MuleSoft projects, allowing you to configure custom rules and track issues based on MuleSoft code standards.

## Notes

- Customize `docker-compose.yaml` as needed for your environment.
- Ensure all network configurations allow SonarQube to communicate with MuleSoft applications.

## Troubleshooting

- **Docker Issues**: Ensure Docker services are running and `docker-compose.yaml` is correctly configured.
- **Plugin Issues**: Check `pom.xml` and ensure all dependencies are correctly resolved.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.