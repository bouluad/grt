#!/bin/bash

# === Configuration ===
BASE_URL="https://artifactory.example.com"
XRAY_URL="$BASE_URL/xray"
USER="your_user"
PASSWORD="your_password"

GENERIC_REPO="generic-dr-test"
GENERIC_PATH="dr-test/test-artifact.txt"
REPORT_FILE="dr_report.log"

NODE_REMOTE_REPO="npm-remote"
JAVA_REMOTE_REPO="maven-remote"
PYTHON_REMOTE_REPO="pypi-remote"

# === Init Report ===
echo "==== DR Sanity Test Report ====" > $REPORT_FILE
echo "Start Time: $(date)" >> $REPORT_FILE

# === Function to append to report ===
log() {
    echo "$1"
    echo "$1" >> $REPORT_FILE
}

# === Health Checks ===
log "▶️ Checking Artifactory health..."
if curl -su $USER:$PASSWORD -f "$BASE_URL/artifactory/api/system/ping" >/dev/null; then
    log "✅ Artifactory is healthy."
else
    log "❌ Artifactory is NOT healthy."
    exit 1
fi

log "▶️ Checking Xray health..."
if curl -su $USER:$PASSWORD -f "$XRAY_URL/api/v1/system/health" >/dev/null; then
    log "✅ Xray is healthy."
else
    log "❌ Xray is NOT healthy."
    exit 1
fi

# === Create repo if needed ===
log "▶️ Checking if generic repo exists..."
status=$(curl -su $USER:$PASSWORD -o /dev/null -w "%{http_code}" "$BASE_URL/artifactory/api/repositories/$GENERIC_REPO")
if [ "$status" -ne 200 ]; then
    log "ℹ️ Creating generic repo..."
    curl -su $USER:$PASSWORD -X PUT "$BASE_URL/artifactory/api/repositories/$GENERIC_REPO" \
        -H "Content-Type: application/json" \
        -d '{"rclass":"local","packageType":"generic","description":"DR Test Repository"}'
    log "✅ Generic repo created."
else
    log "ℹ️ Generic repo already exists."
fi

# === Upload Artifact ===
log "▶️ Creating test artifact..."
echo "DR test content - $(date)" > test-artifact.txt
log "▶️ Uploading artifact..."
curl -su $USER:$PASSWORD -T test-artifact.txt "$BASE_URL/artifactory/$GENERIC_REPO/$GENERIC_PATH"
log "✅ Artifact uploaded."

# === List Artifacts ===
log "▶️ Listing artifacts..."
curl -su $USER:$PASSWORD "$BASE_URL/artifactory/api/storage/$GENERIC_REPO/dr-test/" | jq '.' >> $REPORT_FILE

# === Download Artifact ===
log "▶️ Downloading artifact..."
curl -su $USER:$PASSWORD -o downloaded.txt "$BASE_URL/artifactory/$GENERIC_REPO/$GENERIC_PATH"
log "✅ Artifact downloaded."

# === Delete Artifact ===
log "▶️ Deleting artifact..."
curl -su $USER:$PASSWORD -X DELETE "$BASE_URL/artifactory/$GENERIC_REPO/$GENERIC_PATH"
log "✅ Artifact deleted."

# === Delete Repo ===
log "▶️ Deleting generic repo..."
curl -su $USER:$PASSWORD -X DELETE "$BASE_URL/artifactory/api/repositories/$GENERIC_REPO"
log "✅ Repo deleted."

# === NPM Install Test ===
log "▶️ Testing NPM remote repo..."
mkdir -p npm-test && cd npm-test
npm config set registry "$BASE_URL/artifactory/api/npm/$NODE_REMOTE_REPO"
npm init -y >/dev/null 2>&1
if npm install lodash >/dev/null 2>&1; then
    log "✅ NPM install OK."
else
    log "❌ NPM install FAILED."
fi
cd ..

# === Maven Install Test ===
log "▶️ Testing Maven remote repo..."
mkdir -p maven-test && cd maven-test
cat > pom.xml <<EOF
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.test</groupId>
  <artifactId>drtest</artifactId>
  <version>1.0</version>
  <dependencies>
    <dependency>
      <groupId>junit</groupId>
      <artifactId>junit</artifactId>
      <version>4.13.2</version>
    </dependency>
  </dependencies>
  <repositories>
    <repository>
      <id>artifactory</id>
      <url>$BASE_URL/artifactory/$JAVA_REMOTE_REPO</url>
    </repository>
  </repositories>
</project>
EOF

if mvn dependency:resolve -B >/dev/null 2>&1; then
    log "✅ Maven install OK."
else
    log "❌ Maven install FAILED."
fi
cd ..

# === pip Install Test ===
log "▶️ Testing pip install from remote repo..."
if pip install --index-url "$BASE_URL/artifactory/api/pypi/$PYTHON_REMOTE_REPO/simple" requests >/dev/null 2>&1; then
    log "✅ pip install OK."
else
    log "❌ pip install FAILED."
fi

# === Done ===
log "End Time: $(date)"
log "================================="

cat $REPORT_FILE
