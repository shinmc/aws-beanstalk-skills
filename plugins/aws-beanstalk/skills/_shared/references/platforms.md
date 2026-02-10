# AWS Elastic Beanstalk Platforms Reference

## Platform Overview

AWS Elastic Beanstalk supports multiple platforms. Each platform has specific configuration options and deployment requirements.

## Getting Latest Solution Stacks

> **Important:** Solution stack versions change frequently. Always query for the latest available stacks.

### List All Available Stacks
```bash
aws elasticbeanstalk list-available-solution-stacks --output json
```

### Find Stacks by Platform
```bash
# Node.js
aws elasticbeanstalk list-available-solution-stacks \
  --query 'SolutionStacks[?contains(@, `Node.js`)]' --output table

# Python
aws elasticbeanstalk list-available-solution-stacks \
  --query 'SolutionStacks[?contains(@, `Python`)]' --output table

# Docker
aws elasticbeanstalk list-available-solution-stacks \
  --query 'SolutionStacks[?contains(@, `Docker`)]' --output table

# Java/Corretto
aws elasticbeanstalk list-available-solution-stacks \
  --query 'SolutionStacks[?contains(@, `Corretto`)]' --output table

# .NET
aws elasticbeanstalk list-available-solution-stacks \
  --query 'SolutionStacks[?contains(@, `.NET`) || contains(@, `IIS`)]' --output table
```

### List Platform Branches
```bash
aws elasticbeanstalk list-platform-branches \
  --filters Type=PlatformName,Operator=contains,Values=Node.js \
  --output table
```

---

## Node.js

### Solution Stack Pattern
```
64bit Amazon Linux 2023 v<version> running Node.js <node-version>
```

Find latest:
```bash
aws elasticbeanstalk list-available-solution-stacks \
  --query 'SolutionStacks[?contains(@, `Node.js`)] | [0:3]' --output table
```

### Required Files
- `package.json` - Dependencies and scripts

### Optional Files
- `Procfile` - Custom start command
- `.npmrc` - npm configuration
- `.ebextensions/` - EB configuration

### Default Behavior
- Runs `npm install` to install dependencies
- Runs `npm start` to start application
- Listens on `process.env.PORT` (default: 8080)

### Configuration Options

> **Warning:** The `aws:elasticbeanstalk:container:nodejs` namespace is **AL1 only** (not supported on AL2/AL2023). On AL2/AL2023, use a `Procfile` instead:
> ```
> web: node server.js
> ```

Legacy AL1 only:
```
aws:elasticbeanstalk:container:nodejs:
  NodeCommand: npm start
  ProxyServer: nginx
  GzipCompression: true
```

### Example package.json
```json
{
  "name": "my-app",
  "version": "1.0.0",
  "scripts": {
    "start": "node server.js",
    "build": "npm run compile"
  },
  "engines": {
    "node": "22.x"
  }
}
```

---

## Python

### Solution Stack Pattern
```
64bit Amazon Linux 2023 v<version> running Python <python-version>
```

Find latest:
```bash
aws elasticbeanstalk list-available-solution-stacks \
  --query 'SolutionStacks[?contains(@, `Python`)] | [0:3]' --output table
```

### Required Files
- `requirements.txt` - pip dependencies
- WSGI application file

### Optional Files
- `Procfile` - Custom start command
- `.ebextensions/` - EB configuration

### Default Behavior
- Runs `pip install -r requirements.txt`
- Looks for WSGI application at `application.py:application`
- Uses Gunicorn as WSGI server

### Configuration Options
```
aws:elasticbeanstalk:container:python:
  WSGIPath: application:application
  NumProcesses: 1
  NumThreads: 15
```

### Example Structure
```
├── application.py
├── requirements.txt
└── .ebextensions/
    └── python.config
```

### Example application.py
```python
from flask import Flask
application = Flask(__name__)

@application.route('/')
def index():
    return 'Hello World'

if __name__ == '__main__':
    application.run()
```

---

## Java (Corretto)

### Solution Stack Pattern
```
64bit Amazon Linux 2023 v<version> running Corretto <java-version>
64bit Amazon Linux 2023 v<version> running Tomcat <tomcat-version> Corretto <java-version>
```

Find latest:
```bash
aws elasticbeanstalk list-available-solution-stacks \
  --query 'SolutionStacks[?contains(@, `Corretto`)] | [0:5]' --output table
```

### Deployment Options

#### JAR Deployment
- Upload standalone JAR file
- Use Procfile to specify startup

```
# Procfile
web: java -jar my-app.jar
```

#### WAR Deployment (Tomcat)
- Deploy WAR to Tomcat container
- Place WAR in deployment package root

### JVM Configuration
```
aws:elasticbeanstalk:container:java:
  JVMOptions: -Xms256m -Xmx512m
```

Or via environment variable:
```
JAVA_OPTS=-Xms256m -Xmx512m -XX:+UseG1GC
```

---

## Docker

### Solution Stack Pattern
```
64bit Amazon Linux 2023 v<version> running Docker
```

Find latest:
```bash
aws elasticbeanstalk list-available-solution-stacks \
  --query 'SolutionStacks[?contains(@, `Docker`)] | [0:3]' --output table
```

### Deployment Options

#### Single Container
Use `Dockerfile` (adjust base image version as needed):
```dockerfile
FROM node:lts-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 80
CMD ["npm", "start"]
```

#### Multi-Container
Use `docker-compose.yml`:
```yaml
services:
  web:
    build: .
    ports:
      - "80:3000"
  redis:
    image: redis:alpine
```

### Configuration
```
aws:elasticbeanstalk:environment:proxy:
  ProxyServer: nginx  # or none
```

### Best Practices
- Use multi-stage builds
- Minimize image size
- Don't run as root
- Use .dockerignore

---

## .NET

### Solution Stack Pattern
```
64bit Windows Server <version> running IIS <iis-version>
64bit Amazon Linux 2023 v<version> running .NET <dotnet-version>
```

Find latest:
```bash
aws elasticbeanstalk list-available-solution-stacks \
  --query 'SolutionStacks[?contains(@, `.NET`) || contains(@, `IIS`)] | [0:5]' --output table
```

### Windows Deployment
- Deploy as Web Deploy package
- IIS configuration via `web.config`

### Linux Deployment
- Self-contained deployment
- Use Procfile for startup

### Example Procfile (.NET on Linux)
```
web: dotnet ./myapp.dll
```

---

## Go

### Solution Stack Pattern
```
64bit Amazon Linux 2023 v<version> running Go 1
```

Find latest:
```bash
aws elasticbeanstalk list-available-solution-stacks \
  --query 'SolutionStacks[?contains(@, `Go`)]' --output table
```

### Required Files
- Go modules (`go.mod`, `go.sum`)
- Main application file

### Default Behavior
- Builds using `go build`
- Runs compiled binary
- Listens on port 5000

### Example Structure
```
├── go.mod
├── go.sum
├── main.go
└── Procfile
```

### Example Procfile
```
web: bin/application
```

---

## Ruby

### Solution Stack Pattern
```
64bit Amazon Linux 2023 v<version> running Ruby <ruby-version>
```

Find latest:
```bash
aws elasticbeanstalk list-available-solution-stacks \
  --query 'SolutionStacks[?contains(@, `Ruby`)]' --output table
```

### Required Files
- `Gemfile` - Ruby dependencies
- `config.ru` - Rack configuration

### Default Behavior
- Runs `bundle install`
- Uses Puma as application server
- Looks for Rack config

### Configuration

> **Note:** On AL2023, the Ruby version is determined by the solution stack — there is no configuration option to change it. Use a `Procfile` for custom start commands:
> ```
> web: bundle exec puma -C config/puma.rb
> ```

---

## PHP

### Solution Stack Pattern
```
64bit Amazon Linux 2023 v<version> running PHP <php-version>
```

Find latest:
```bash
aws elasticbeanstalk list-available-solution-stacks \
  --query 'SolutionStacks[?contains(@, `PHP`)]' --output table
```

### Required Files
- `composer.json` (optional) - PHP dependencies

### Default Behavior
- Runs `composer install` if composer.json exists
- Serves from document root
- Apache or Nginx as web server

### Configuration
```
aws:elasticbeanstalk:container:php:phpini:
  document_root: /public
  memory_limit: 256M
  max_execution_time: 60
```

---

## Platform Comparison

| Platform | Default Port | Build Tool | Server |
|----------|-------------|------------|--------|
| Node.js | 8080 | npm | Node.js + nginx |
| Python | 8000 | pip | Gunicorn + nginx |
| Java JAR | 5000 | Maven/Gradle | Java |
| Java WAR | 8080 | Maven/Gradle | Tomcat |
| Docker | 80 | Docker | Varies |
| .NET | 5000 | dotnet | Kestrel/IIS |
| Go | 5000 | go build | Go binary |
| Ruby | 3000 | bundler | Puma + nginx |
| PHP | 80 | composer | Apache/nginx |

## Common Procfile Examples

```bash
# Node.js
web: npm start
web: node server.js

# Python
web: gunicorn application:application
web: python manage.py runserver

# Java
web: java -jar target/myapp.jar
web: java -Xmx512m -jar app.jar

# Go
web: bin/application

# Ruby
web: bundle exec puma -C config/puma.rb
```
