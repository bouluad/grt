# ----------- NPM INSTALL CHECK WITH AUTH -------------

echo "🔐 Setting up npm config for private remote repository..."

# Define variables
NPM_REGISTRY_URL="$BASE_URL/artifactory/api/npm/npm-remote/"
AUTH_TOKEN=$(echo -n "${USER}:${PASSWORD}" | base64)

# Create a temporary folder for npm test
mkdir -p npm_test && cd npm_test
npm init -y > /dev/null

# Set npm registry and auth for scoped or all packages
npm config set registry "$NPM_REGISTRY_URL"
npm config set always-auth true
npm config set //$(echo "$NPM_REGISTRY_URL" | sed -e 's|^https\?://||'):_auth "$AUTH_TOKEN"

# Optional: Use token via .npmrc
echo "//$(echo "$NPM_REGISTRY_URL" | sed -e 's|^https\?://||'):_auth=$AUTH_TOKEN" > .npmrc
echo "always-auth=true" >> .npmrc
echo "registry=$NPM_REGISTRY_URL" >> .npmrc

# Perform install
echo "📦 Installing lodash from private Artifactory registry..."
if npm install lodash --prefer-online &> ../dr_report.log; then
  echo "✅ NPM install success!" | tee -a ../dr_report.log
else
  echo "❌ NPM install failed." | tee -a ../dr_report.log
fi

# Clean up
cd ..
rm -rf npm_test
