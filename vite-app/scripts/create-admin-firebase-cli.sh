#!/bin/bash

# Script to create admin user using Firebase CLI
# This script uses Firebase CLI to authenticate and then creates admin users via Admin SDK

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI is not installed${NC}"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

# Parse arguments
EMAIL=$1
PASSWORD=$2
ROLE=${3:-admin}
DISPLAY_NAME=${4:-"Admin User"}

# Validate arguments
if [ -z "$EMAIL" ] || [ -z "$PASSWORD" ]; then
    echo -e "${RED}❌ Usage: ./create-admin-firebase-cli.sh <email> <password> [role] [displayName]${NC}"
    echo "   Roles: super_admin, admin, librarian"
    exit 1
fi

# Validate role
if [[ ! "$ROLE" =~ ^(super_admin|admin|librarian)$ ]]; then
    echo -e "${RED}❌ Invalid role. Must be one of: super_admin, admin, librarian${NC}"
    exit 1
fi

echo -e "${GREEN}🔥 Using Firebase CLI to create admin user${NC}"
echo ""

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to Firebase. Logging in...${NC}"
    firebase login
fi

# Get current project
PROJECT_ID=$(firebase use 2>&1 | grep -oP '(?<=\* ).*' || echo "spyware-7bfe6")
echo -e "${GREEN}✅ Using Firebase project: ${PROJECT_ID}${NC}"
echo ""

# Check if service account exists
if [ ! -f "firebase-service-account.json" ]; then
    echo -e "${YELLOW}⚠️  Service account key not found${NC}"
    echo "Please download it from Firebase Console:"
    echo "1. Go to Project Settings > Service Accounts"
    echo "2. Click 'Generate new private key'"
    echo "3. Save as firebase-service-account.json"
    exit 1
fi

# Use Node.js script with Firebase Admin SDK
echo -e "${GREEN}Creating admin user...${NC}"
echo "Email: $EMAIL"
echo "Role: $ROLE"
echo "Display Name: $DISPLAY_NAME"
echo ""

node scripts/create-admin.js "$EMAIL" "$PASSWORD" "$ROLE" "$DISPLAY_NAME"

