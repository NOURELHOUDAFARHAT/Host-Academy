#!/bin/bash

# GitHub Actions Setup Script for Host Academy
# This script helps you set up the necessary secrets and configurations

echo "🚀 Host Academy - GitHub Actions Setup"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is not installed. Please install it first:"
    echo "https://cli.github.com/manual/installation"
    exit 1
fi

# Check if user is logged in to GitHub CLI
if ! gh auth status &> /dev/null; then
    print_error "You're not logged in to GitHub CLI. Please run: gh auth login"
    exit 1
fi

print_step "Setting up GitHub repository secrets..."

# Function to set a secret
set_secret() {
    local secret_name=$1
    local secret_description=$2
    local is_required=${3:-true}
    
    echo ""
    print_step "Setting up $secret_name"
    echo "Description: $secret_description"
    
    if [ "$is_required" = "true" ]; then
        echo -n "Enter value for $secret_name: "
        read -s secret_value
        echo ""
        
        if [ -n "$secret_value" ]; then
            if gh secret set "$secret_name" --body "$secret_value"; then
                print_success "$secret_name set successfully"
            else
                print_error "Failed to set $secret_name"
            fi
        else
            print_warning "$secret_name skipped (empty value)"
        fi
    else
        echo -n "Enter value for $secret_name (optional): "
        read -s secret_value
        echo ""
        
        if [ -n "$secret_value" ]; then
            if gh secret set "$secret_name" --body "$secret_value"; then
                print_success "$secret_name set successfully"
            else
                print_error "Failed to set $secret_name"
            fi
        else
            print_warning "$secret_name skipped (optional)"
        fi
    fi
}

# Required secrets
echo ""
print_step "🔑 Required Secrets"
echo "=================="

set_secret "DOCKERHUB_USERNAME" "Your Docker Hub username (for pushing images)"
set_secret "DOCKERHUB_TOKEN" "Your Docker Hub access token"

echo ""
print_step "📢 Notification Secrets (Optional)"
echo "================================="

set_secret "DISCORD_WEBHOOK" "Discord webhook URL for notifications" false
set_secret "SLACK_WEBHOOK" "Slack webhook URL for deployment notifications" false

echo ""
print_step "🔒 Security & Quality Tool Secrets (Optional)"
echo "============================================="

set_secret "SNYK_TOKEN" "Snyk authentication token for security scanning" false
set_secret "SONAR_TOKEN" "SonarCloud authentication token for code quality" false
set_secret "CODECOV_TOKEN" "Codecov upload token for test coverage" false

# Environment setup
echo ""
print_step "🌍 Setting up repository environments..."

# Create staging environment
if gh api repos/:owner/:repo/environments/staging --silent 2>/dev/null; then
    print_success "Staging environment already exists"
else
    if gh api repos/:owner/:repo/environments -f name=staging; then
        print_success "Staging environment created"
    else
        print_error "Failed to create staging environment"
    fi
fi

# Create production environment with protection rules
if gh api repos/:owner/:repo/environments/production --silent 2>/dev/null; then
    print_success "Production environment already exists"
else
    if gh api repos/:owner/:repo/environments -f name=production; then
        print_success "Production environment created"
        
        # Add protection rules (require manual approval)
        gh api repos/:owner/:repo/environments/production -X PUT --input - <<EOF
{
  "wait_timer": 0,
  "reviewers": [
    {
      "type": "User",
      "id": $(gh api user --jq '.id')
    }
  ],
  "deployment_branch_policy": {
    "protected_branches": true,
    "custom_branch_policies": false
  }
}
EOF
        print_success "Production environment protection rules added"
    else
        print_error "Failed to create production environment"
    fi
fi

# Summary
echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "Next steps:"
echo "1. Push your code to trigger the workflows"
echo "2. Check the Actions tab in your GitHub repository"
echo "3. Review the workflow runs and logs"
echo "4. Set up additional integrations if needed:"
echo "   - SonarCloud: https://sonarcloud.io/"
echo "   - Snyk: https://snyk.io/"
echo "   - Codecov: https://codecov.io/"
echo ""
echo "📖 For detailed documentation, see .github/WORKFLOWS.md"
echo ""
print_success "GitHub Actions is now configured for Host Academy!"
