#!/bin/bash

PROJECT_NAME="ShellConfigManager"
SCHEME="ShellConfigManager"
CONFIGURATION="Debug"
DERIVED_DATA_PATH="./build"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 is not installed. Please install it first."
        exit 1
    fi
}

generate_project() {
    if [ -f "project.yml" ]; then
        log_info "Generating Xcode project with XcodeGen..."
        xcodegen generate
        if [ $? -eq 0 ]; then
            log_success "Project generated successfully"
        else
            log_error "Failed to generate project"
            exit 1
        fi
    else
        log_warning "No project.yml found, skipping project generation"
    fi
}

build_project() {
    log_info "Building $PROJECT_NAME..."
    
    xcodebuild \
        -project "$PROJECT_NAME.xcodeproj" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        clean build \
        | xcpretty --color --simple
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_success "Build completed successfully"
        return 0
    else
        log_error "Build failed"
        return 1
    fi
}

run_app() {
    local app_path="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$PROJECT_NAME.app"
    
    if [ -d "$app_path" ]; then
        log_info "Launching $PROJECT_NAME..."
        open "$app_path"
        log_success "Application launched"
    else
        log_error "Application bundle not found at: $app_path"
        exit 1
    fi
}

clean_build() {
    log_info "Cleaning build directory..."
    rm -rf "$DERIVED_DATA_PATH"
    log_success "Build directory cleaned"
}

show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  build    - Build the project (default)"
    echo "  run      - Build and run the application"
    echo "  clean    - Clean build directory"
    echo "  gen      - Generate Xcode project only"
    echo "  help     - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0          # Build project"
    echo "  $0 run      # Build and run"
    echo "  $0 clean    # Clean build files"
}

main() {
    cd "$(dirname "$0")"
    
    check_command "xcodebuild"
    
    local command=${1:-build}
    
    case $command in
        build)
            generate_project
            build_project
            ;;
        run)
            generate_project
            if build_project; then
                run_app
            fi
            ;;
        clean)
            clean_build
            ;;
        gen)
            check_command "xcodegen"
            generate_project
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
