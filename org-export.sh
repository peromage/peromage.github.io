#!/bin/sh

# Working directory check
if [ ! -f org-export.sh ]; then
    echo "Not in the blog root directory"
    exit 1
fi

# Cleaning
if [ -d content ]; then
    rm -rf content
fi

emacs -Q -nw --batch --eval \
      '(progn
         (package-initialize)
         (add-to-list (quote package-archives) (quote ("melpa" . "https://melpa.org/packages/")))
         (package-refresh-contents)
         (package-install (quote ox-hugo))
         (find-file "myblog/blog.org")
         (org-hugo-export-wim-to-md :all))'
