#!/bin/sh

# Working directory check
if [ ! -f "ox-hugo-export.sh" ]; then
    echo "Not in the blog root directory"
    exit 1
fi

# Cleaning
if [ -d "content" ]; then
    rm -rf content
fi

emacs -nw --batch --eval \
      '(progn
         (package-initialize)
         (add-to-list (quote package-archives) (quote ("melpa" . "https://melpa.org/packages/")))
         (package-refresh-contents)
         (package-install (quote ox-hugo))
         (require (quote org))
         (require (quote org-id))
         (find-file "blog/blog.org")
         (org-hugo-export-wim-to-md :all)
         (org-babel-tangle))'
