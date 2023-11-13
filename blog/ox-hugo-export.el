;; Elisp script file which should be executed with `emacs --script'.

;; Use `ox-hugo' to convert org files to markdown files.

(require 'subr-x)

;; Helper functions
(defun new-option (opt)
  (format "%s=\\(.*\\)" opt))

(defun check-option (opt arg)
  (if (string-match (new-option opt) arg)
      (match-string 1 arg)
    nil))

(defun parse-option (opt args)
  "Return the option value or empty string."
  (let ((args args)
        (v nil))
    (pop args) ;; Skip the leading "--"
    (while args
      (if (setq v (check-option opt (car args)))
          (setq args nil)
        (pop args)))
    (if v v "")))

;; Process arguments
(when (or (string-empty-p (setq my-hugo-dir (parse-option "--hugo-dir" argv)))
          (string-empty-p (setq my-blog-dir (parse-option "--blog-dir" argv))))
  (error "Missing arguments")
  (kill-emacs 1))

;; Install packages
(package-initialize)
(add-to-list (quote package-archives) (quote ("melpa" . "https://melpa.org/packages/")))
(package-refresh-contents)
(package-install (quote ox-hugo))

;; Load packages
(require 'org)
(require 'org-id)
;; (setq safe-local-variable-values
;;       '((eval setq org-hugo-base-dir (expand-file-name my-hugo-dir))))

;; Export
(let ((default-directory (expand-file-name my-blog-dir))
      (org-confirm-babel-evaluate nil)
      (org-hugo-base-dir (expand-file-name my-hugo-dir))
      (enable-local-variables :all))
  ;; Export posts
  (dolist (post (file-expand-wildcards "**/*.org"))
    (message ">> Exporting %s" post)
    (find-file post)
    (org-hugo-export-to-md)
    (kill-buffer))
  ;; Export navigation pages
  (find-file "pages.org")
  (org-hugo-export-wim-to-md :all-subtrees)
  (kill-buffer))
