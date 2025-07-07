# GitHub Actions Setup Script for Host Academy (PowerShell)
# This script helps you set up the necessary secrets and configurations

Write-Host "🚀 Host Academy - GitHub Actions Setup" -ForegroundColor Blue
Write-Host "======================================" -ForegroundColor Blue

function Write-Step {
    param($Message)
    Write-Host "📋 $Message" -ForegroundColor Cyan
}

function Write-Success {
    param($Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param($Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param($Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Check if GitHub CLI is installed
try {
    gh --version | Out-Null
} catch {
    Write-Error "GitHub CLI (gh) is not installed. Please install it first:"
    Write-Host "https://cli.github.com/manual/installation"
    exit 1
}

# Check if user is logged in to GitHub CLI
try {
    gh auth status 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Not logged in"
    }
} catch {
    Write-Error "You're not logged in to GitHub CLI. Please run: gh auth login"
    exit 1
}

Write-Step "Setting up GitHub repository secrets..."

# Function to set a secret
function Set-Secret {
    param(
        [string]$SecretName,
        [string]$SecretDescription,
        [bool]$IsRequired = $true
    )
    
    Write-Host ""
    Write-Step "Setting up $SecretName"
    Write-Host "Description: $SecretDescription"
    
    if ($IsRequired) {
        $SecretValue = Read-Host -Prompt "Enter value for $SecretName" -AsSecureString
        $SecretValuePlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecretValue))
        
        if ($SecretValuePlain) {
            try {
                gh secret set $SecretName --body $SecretValuePlain
                Write-Success "$SecretName set successfully"
            } catch {
                Write-Error "Failed to set $SecretName"
            }
        } else {
            Write-Warning "$SecretName skipped (empty value)"
        }
    } else {
        $SecretValue = Read-Host -Prompt "Enter value for $SecretName (optional)" -AsSecureString
        $SecretValuePlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecretValue))
        
        if ($SecretValuePlain) {
            try {
                gh secret set $SecretName --body $SecretValuePlain
                Write-Success "$SecretName set successfully"
            } catch {
                Write-Error "Failed to set $SecretName"
            }
        } else {
            Write-Warning "$SecretName skipped (optional)"
        }
    }
}

# Required secrets
Write-Host ""
Write-Step "🔑 Required Secrets"
Write-Host "=================="

Set-Secret -SecretName "DOCKERHUB_USERNAME" -SecretDescription "Your Docker Hub username (for pushing images)"
Set-Secret -SecretName "DOCKERHUB_TOKEN" -SecretDescription "Your Docker Hub access token"

Write-Host ""
Write-Step "📢 Notification Secrets (Optional)"
Write-Host "================================="

Set-Secret -SecretName "DISCORD_WEBHOOK" -SecretDescription "Discord webhook URL for notifications" -IsRequired $false
Set-Secret -SecretName "SLACK_WEBHOOK" -SecretDescription "Slack webhook URL for deployment notifications" -IsRequired $false

Write-Host ""
Write-Step "🔒 Security & Quality Tool Secrets (Optional)"
Write-Host "============================================="

Set-Secret -SecretName "SNYK_TOKEN" -SecretDescription "Snyk authentication token for security scanning" -IsRequired $false
Set-Secret -SecretName "SONAR_TOKEN" -SecretDescription "SonarCloud authentication token for code quality" -IsRequired $false
Set-Secret -SecretName "CODECOV_TOKEN" -SecretDescription "Codecov upload token for test coverage" -IsRequired $false

# Environment setup
Write-Host ""
Write-Step "🌍 Setting up repository environments..."

# Create staging environment
try {
    gh api repos/:owner/:repo/environments/staging --silent 2>$null
    Write-Success "Staging environment already exists"
} catch {
    try {
        gh api repos/:owner/:repo/environments -f name=staging
        Write-Success "Staging environment created"
    } catch {
        Write-Error "Failed to create staging environment"
    }
}

# Create production environment
try {
    gh api repos/:owner/:repo/environments/production --silent 2>$null
    Write-Success "Production environment already exists"
} catch {
    try {
        gh api repos/:owner/:repo/environments -f name=production
        Write-Success "Production environment created"
        
        # Note: PowerShell version doesn't set protection rules automatically
        Write-Warning "Please manually configure production environment protection rules in GitHub"
    } catch {
        Write-Error "Failed to create production environment"
    }
}

# Summary
Write-Host ""
Write-Host "🎉 Setup Complete!" -ForegroundColor Green
Write-Host "=================="
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Push your code to trigger the workflows"
Write-Host "2. Check the Actions tab in your GitHub repository"
Write-Host "3. Review the workflow runs and logs"
Write-Host "4. Set up additional integrations if needed:"
Write-Host "   - SonarCloud: https://sonarcloud.io/"
Write-Host "   - Snyk: https://snyk.io/"
Write-Host "   - Codecov: https://codecov.io/"
Write-Host ""
Write-Host "📖 For detailed documentation, see .github/WORKFLOWS.md"
Write-Host ""
Write-Success "GitHub Actions is now configured for Host Academy!"
