#!/bin/sh

THIS_FILE="deploy.sh"

## Working directory check
if [ ! -f "$THIS_FILE" ]; then
    echo "Current working directory is not the project root. Aborting..."
    exit 1
fi

## Save root directory
REPO_ROOT="$(pwd)"
HUGO_BASE_DIR="${REPO_ROOT}/hugo"
HUGO_BASE_CONTENT_DIR="${HUGO_BASE_DIR}/content"
BLOG_BASE_DIR="${REPO_ROOT}/blog"
SELECTED_SUBCOMMAND="cmd_export_and_build"
HUGO_ENVIRONMENT="current"

## Logging function
logd() {
    echo "[$THIS_FILE] $@"
}

## Subcommands
cmd_export() {
    ## Cleaning
    if [ -d "$HUGO_BASE_CONTENT_DIR" ]; then
        logd "Cleaning old exported content: $HUGO_BASE_CONTENT_DIR"
        rm -rf "$HUGO_BASE_CONTENT_DIR"
    fi

    logd "Exporting from org files"
    cd "$BLOG_BASE_DIR"
    emacs --script ox-hugo-export.el -- "--hugo-dir=$HUGO_BASE_DIR" "--blog-dir=$BLOG_BASE_DIR"
}

cmd_build() {
    logd "Building Hugo static files using environment($HUGO_ENVIRONMENT)"
    cd "$HUGO_BASE_DIR"
    hugo --minify --environment "$HUGO_ENVIRONMENT"
}

cmd_export_and_build() {
    cmd_export || exit $?
    cmd_build || exit $?
}

cmd_server() {
    cd "$HUGO_BASE_DIR"
    logd "Starting Hugo server using environment($HUGO_ENVIRONMENT)"
    hugo server --disableFastRender --environment "$HUGO_ENVIRONMENT"
}

## CLI: Choose a subcommand
case $1 in
    server)
        SELECTED_SUBCOMMAND="cmd_server" && shift
        ;;
    export)
        SELECTED_SUBCOMMAND="cmd_export" && shift
        ;;
    build)
        SELECTED_SUBCOMMAND="cmd_build" && shift
        ;;
    export-build)
        SELECTED_SUBCOMMAND="cmd_export_and_build" && shift
        ;;
    *)
        SELECTED_SUBCOMMAND="cmd_export_and_build"
        ;;
esac

## CLI: Process arguments
for i in $@; do
    case $i in
        --environment)
            shift && HUGO_ENVIRONMENT="$1"
            ;;
        *) :; ;;
    esac
done

## Run the subcommand
eval $SELECTED_SUBCOMMAND
