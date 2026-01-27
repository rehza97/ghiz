#!/bin/bash

# Firebase CLI Utilities Script
# Helper functions for common Firebase operations

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if Firebase CLI is installed
check_firebase_cli() {
    if ! command -v firebase &> /dev/null; then
        echo "❌ Firebase CLI is not installed"
        echo "Install it with: npm install -g firebase-tools"
        exit 1
    fi
}

# Login to Firebase
firebase_login() {
    echo -e "${BLUE}🔐 Logging in to Firebase...${NC}"
    firebase login
}

# Initialize Firebase project
firebase_init() {
    echo -e "${BLUE}🚀 Initializing Firebase project...${NC}"
    firebase init
}

# Set Firebase project
firebase_use() {
    local project_id=$1
    if [ -z "$project_id" ]; then
        echo -e "${YELLOW}Usage: firebase_use <project-id>${NC}"
        echo "Available projects:"
        firebase projects:list
        return 1
    fi
    echo -e "${GREEN}✅ Setting Firebase project to: $project_id${NC}"
    firebase use "$project_id"
}

# Deploy Firestore rules
deploy_firestore_rules() {
    echo -e "${BLUE}📝 Deploying Firestore rules...${NC}"
    firebase deploy --only firestore:rules
}

# Deploy Firestore indexes
deploy_firestore_indexes() {
    echo -e "${BLUE}📊 Deploying Firestore indexes...${NC}"
    firebase deploy --only firestore:indexes
}

# Deploy Storage rules
deploy_storage_rules() {
    echo -e "${BLUE}📦 Deploying Storage rules...${NC}"
    firebase deploy --only storage
}

# Deploy hosting
deploy_hosting() {
    echo -e "${BLUE}🌐 Deploying hosting...${NC}"
    # Build first
    npm run build
    firebase deploy --only hosting
}

# Deploy everything
deploy_all() {
    echo -e "${BLUE}🚀 Deploying everything...${NC}"
    npm run build
    firebase deploy
}

# Start emulators
start_emulators() {
    echo -e "${BLUE}🔄 Starting Firebase emulators...${NC}"
    firebase emulators:start
}

# Export Firestore data
export_firestore() {
    local output_file=${1:-"firestore-export-$(date +%Y%m%d-%H%M%S)"}
    echo -e "${BLUE}💾 Exporting Firestore data to: $output_file${NC}"
    firebase firestore:export "$output_file"
}

# Import Firestore data
import_firestore() {
    local input_file=$1
    if [ -z "$input_file" ]; then
        echo -e "${YELLOW}Usage: import_firestore <backup-directory>${NC}"
        return 1
    fi
    echo -e "${BLUE}📥 Importing Firestore data from: $input_file${NC}"
    firebase firestore:import "$input_file"
}

# List users
list_users() {
    echo -e "${BLUE}👥 Listing Firebase Auth users...${NC}"
    firebase auth:export users.json --format=json 2>/dev/null || {
        echo "Note: User export requires Firebase Admin SDK. Use the admin dashboard instead."
    }
}

# Show project info
show_project_info() {
    echo -e "${GREEN}📋 Firebase Project Information${NC}"
    echo "======================================"
    CURRENT_PROJECT=$(firebase use 2>&1 | grep -E '^\s+\*' | sed 's/.*\* //' | head -n1)
    if [ -z "$CURRENT_PROJECT" ]; then
        CURRENT_PROJECT="Not set"
    fi
    echo "Current Project: $CURRENT_PROJECT"
    echo ""
    echo "Available Projects:"
    firebase projects:list
}

# Show help
show_help() {
    echo -e "${GREEN}Firebase CLI Utilities${NC}"
    echo "====================="
    echo ""
    echo "Available functions:"
    echo "  firebase_login              - Login to Firebase"
    echo "  firebase_init               - Initialize Firebase project"
    echo "  firebase_use <project-id>   - Set active project"
    echo "  deploy_firestore_rules      - Deploy Firestore rules"
    echo "  deploy_firestore_indexes    - Deploy Firestore indexes"
    echo "  deploy_storage_rules        - Deploy Storage rules"
    echo "  deploy_hosting              - Deploy hosting (builds first)"
    echo "  deploy_all                  - Deploy everything"
    echo "  start_emulators             - Start Firebase emulators"
    echo "  export_firestore [path]     - Export Firestore data"
    echo "  import_firestore <path>     - Import Firestore data"
    echo "  list_users                  - List Auth users"
    echo "  show_project_info           - Show project information"
    echo ""
    echo "Usage:"
    echo "  source scripts/firebase-cli-utils.sh"
    echo "  firebase_login"
    echo "  deploy_all"
}

