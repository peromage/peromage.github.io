#!/bin/sh

## Working directory check
if [ ! -f "build.sh" ]; then
    echo "Wrong working directory"
    exit 1
fi

## Save root directory
repo_root="$(pwd)"
hugo_base_dir="${repo_root}/hugo"
blog_base_dir="${repo_root}/blog"

logd() {
    echo "[build.sh] $@"
}

hugo_export() {
    ## Cleaning
    if [ -d "hugo/content" ]; then
        logd "Cleaning content"
        rm -rf hugo/content
    fi

    logd "Exporting from org files"
    cd $blog_base_dir
    emacs --script ox-hugo-export.el
}

hugo_build() {
    logd "Building static files"
    cd $hugo_base_dir
    hugo --minify --environment "$1"
}

hugo_export_and_build() {
    hugo_export
    hugo_build
}

hugo_start_server() {
    cd $hugo_base_dir
    hugo server --disableFastRender --environment "$1"
}

## Subcommands
command_to_run="hugo_export_and_build"

case $1 in
    server)
        command_to_run="hugo_start_server" && shift
        ;;
    export)
        command_to_run="hugo_export" && shift
        ;;
    build)
        command_to_run="hugo_build" && shift
        ;;
    *) :; ;;
esac

## Arguments
environment="current"

for i in $@; do
    case $i in
        --environment)
            shift && environment="$1"
            ;;
        *) :; ;;
    esac
done

logd "Use environment $environment"
eval $command_to_run $environment
