;;; -*- mode: lisp-data; -*-

;; Global ox-hugo settings
;; File local variable can override this.
((org-mode . ((eval . (setq org-hugo-base-dir (locate-dominating-file default-directory ".git"))))))
