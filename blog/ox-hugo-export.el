;; Elisp script file which should be executed with `emacs --script'.

;; Use `ox-hugo' to convert org files to markdown files.

;; Check working directory first
(unless (file-exists-p "ox-hugo-export.el")
  (error "Wrong working directory.  Aborting"))

;; Install packages
(package-initialize)
(add-to-list (quote package-archives) (quote ("melpa" . "https://melpa.org/packages/")))
(package-refresh-contents)
(package-install (quote ox-hugo))

;; Setup
(require 'org)
(require 'org-id)
(setq org-confirm-babel-evaluate nil)
(setq safe-local-variable-values
      '((eval setq org-hugo-base-dir
             (expand-file-name
              "hugo"
              (locate-dominating-file default-directory ".git")))))

;; Export posts
(dolist (post (file-expand-wildcards "**/*.org"))
  (message ">> Exporting %s" post)
  (find-file post)
  (org-hugo-export-to-md)
  (kill-buffer))

;; Export navigation pages
(find-file "pages.org")
(org-hugo-export-wim-to-md :all-subtrees)
