#!/bin/sh

## Working directory check
if [ ! -f "build.sh" ]; then
    echo "Wrong working directory"
    exit 1
fi

## Cleaning
if [ -d "hugo/content" ]; then
    rm -rf hugo/content
fi

## Save root directory
repo_root=$(pwd)

## Export
cd $repo_root/blog
emacs --script ox-hugo-export.el

## Build
cd $repo_root/hugo
hugo --minify
