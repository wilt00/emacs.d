;;; init.el --- Emacs startup file -*- mode: elisp -*-

;;; Commentary:

;; Setup notes:
;; Font
;; - $ scoop bucket add nerd-fonts
;;   $ scoop install iosevka-nf
;; Microsoft Mouse and Keyboard Center
;; - Fix broken scrolling issue
;; - under 'Vertical Scrolling', add Emacs to "programs that don't scroll correctly"
;;   to fix partial line scrolling issue
;; - Seems related to fractional line scrolling issues

;;; Code:

(setq-default buffer-file-coding-system 'utf-8-unix) ; Use LF
(setq buffer-file-coding-system 'utf-8-unix)

(setq straight-repository-branch "develop")
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'benchmark-init)
(benchmark-init/activate)
(add-hook 'after-init-hook 'benchmark-init/deactivate)

(straight-use-package 'use-package)
(setq straight-use-package-by-default t)

;; Org needs to be loaded early to avoid mismatch with builtin org
(use-package org
  :custom
  (org-todo-keywords '((sequence "UPNEXT(u!)" "INPROGRESS(i!)" "ONGOING(o!)" "BLOCKED(b!)" "|" "DONE(d!)"))))

;; UTF-8 all the things
(set-terminal-coding-system 'utf-8)
(set-language-environment 'utf-8)
(set-keyboard-coding-system 'utf-8)
(prefer-coding-system 'utf-8)
(setq locale-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)

(setq inhibit-splash-screen t)
(setq indent-tabs-mode nil)                   ; Don't use tabs for indentation or alignment

(transient-mark-mode)                         ; Enable transient mark mode, default in v23 and newer
(setq-default visible-bell t)                 ; Disable Windows bell
(tool-bar-mode 0)                             ; Hide icon bar

(recentf-mode 1)                              ; Recent files
(run-at-time nil (* 5 60) 'recentf-save-list) ;
(desktop-save-mode 1)                         ; Reopen files on program launch

(define-key global-map (kbd "C-z") 'undo)
(define-key global-map (kbd "C-/") 'isearch-forward)
(define-key global-map (kbd "C-s") 'save-buffer)
(define-key global-map (kbd "C-v") 'yank)
;; (define-key org-mode-map (kbd "C-v") 'org-yank)

;; (if (display-graphic-p)
;;     (progn
;;       ;; (add-to-list 'default-frame-alist '(alpha . 95))
;;       (set-frame-width (selected-frame) 105)
;;       (set-frame-height (selected-frame) 70)))

;; (setq backup-directory-alist
;;       `(("." . ,(concat user-emacs-directory "backups"))))
;; (setq auto-save-file-name-transforms
;;       `((".*" ,user-temporary-file-directory

(defvar user-temporary-file-directory
  (concat temporary-file-directory user-login-name "/"))
(make-directory user-temporary-file-directory t)
(setq backup-by-copying t)
(setq backup-directory-alist
      `(("." . ,user-temporary-file-directory)
        (,tramp-file-name-regexp nil)))
(setq auto-save-list-file-prefix
      (concat user-temporary-file-directory ".auto-saves-"))
(setq auto-save-file-name-transforms
      `((".*" ,user-temporary-file-directory t)))

;; lockfiles start with .#
;; before version 28, could not be moved
(if (version< emacs-version "28")
    (setq create-lockfiles nil)
  (setq lock-file-name-transforms `((".*" ,user-temporary-file-directory t))))

;; https://stackoverflow.com/questions/28221079/ctrl-backspace-in-emacs-deletes-too-much
(defun wilt/backward-kill-word ()
  "Remove all whitespace if the character behind the cursor is whitespace, otherwise remove a word."
  (interactive)
  (if (looking-back "[ \n]")
      ;; delete horizontal space before us and then check to see if we
      ;; are looking at a newline
      (progn (delete-horizontal-space 't)
             (while (looking-back "[ \n]")
               (backward-delete-char 1)))
    ;; otherwise, just do the normal kill word.
    (backward-kill-word 1)))
;; TODO: issue with org-mode headlines

;; (global-set-key  [C-backspace] 'wilt/backward-kill-word)

;; http://xahlee.info/emacs/emacs/emacs_auto_save.html
(defun xah-save-all-unsaved ()
  "Save all unsaved files. no ask. Version 2019-11-05"
  (interactive)
  (save-some-buffers t))

(if (version< emacs-version "27")
    (add-hook 'focus-out-hook 'xah-save-all-unsaved)
  (setq after-focus-change-function 'xah-save-all-unsaved))

(use-package modus-themes
  :config (load-theme 'modus-operandi t))

(use-package which-key :config (which-key-mode))

(use-package flycheck :config (global-flycheck-mode))

(use-package vertico
  :init
  (vertico-mode))
;; (use-package vertico
;;   :custom
;;   (vertico-resize t)
;;   :general
;;   (:keymaps 'vertico-map
;;      "<tab>" #'vertico-insert ; Insert selected candidate into text area
;;      "<escape>" #'minibuffer-keyboard-quit)
;;   :init (vertico-mode))

(use-package corfu
  :straight (:files (:defaults "extensions/*.el"))
  :custom
  (corfu-auto t)
  (corfu-cycle t)
  (corfu-auto-delay 0)
  (corfu-auto-prefix 2)
  (corfu-quit-no-match 'separator)
  (corfu-popupinfo-delay 0)
  (tab-always-indent 'complete)
  (completion-styles '(basic))
  :bind (:map corfu-map ("RET" . nil))
  :init
  (global-corfu-mode)
  (corfu-history-mode t)
  :config
  (add-hook 'corfu-mode-hook #'corfu-popupinfo-mode))

(use-package kind-icon
  :after corfu
  :custom (kind-icon-default-face 'corfu-default)
  :config (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-elisp-block))

(use-package savehist :init (savehist-mode))
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :bind (:map minibuffer-local-map ("M-A" . marginalia-cycle))
  :init (marginalia-mode))

(use-package consult
  :bind (;; C-c bindings in `mode-specific-map'
         ("C-c M-x"           . consult-mode-command)
         ("C-c h"             . consult-history)
         ("C-c k"             . consult-kmacro)
         ("C-c m"             . consult-man)
         ("C-c i"             . consult-info)
         ([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:"           . consult-complex-command)     ;; orig. repeat-complex-command
         ("C-x b"             . consult-buffer)              ;; orig. switch-to-buffer
         ("C-x 4 b"           . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b"           . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
         ("C-x r b"           . consult-bookmark)            ;; orig. bookmark-jump
         ("C-x p b"           . consult-project-buffer)      ;; orig. project-switch-to-buffer
         ;; Custom M-# bindings for fast register access
         ("M-#"               . consult-register-load)
         ("M-'"               . consult-register-store)      ;; orig. abbrev-prefix-mark (unrelated)
         ("C-M-#"             . consult-register)
         ;; Other custom bindings
         ("M-y"               . consult-yank-pop)            ;; orig. yank-pop
         ;; M-g bindings in `goto-map'
         ("M-g e"             . consult-compile-error)
         ("M-g f"             . consult-flycheck)
         ("M-g g"             . consult-goto-line)           ;; orig. goto-line
         ("M-g M-g"           . consult-goto-line)           ;; orig. goto-line
         ("M-g o"             . consult-outline)
         ("M-g m"             . consult-mark)
         ("M-g k"             . consult-global-mark)
         ("M-g i"             . consult-imenu)
         ("M-g I"             . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d"             . consult-find)
         ("M-s D"             . consult-locate)
         ("M-s g"             . consult-grep)
         ("M-s G"             . consult-git-grep)
         ("M-s r"             . consult-ripgrep)
         ("M-s l"             . consult-line)
         ("M-s L"             . consult-line-multi)
         ("M-s k"             . consult-keep-lines)
         ("M-s u"             . consult-focus-lines)
         ;; Isearch integration
         ("M-s e"             . consult-isearch-history)
         :map isearch-mode-map
         ("M-e"               . consult-isearch-history)     ;; orig. isearch-edit-string
         ("M-s e"             . consult-isearch-history)     ;; orig. isearch-edit-string
         ("M-s l"             . consult-line)                ;; ne
         ("M-s L"             . consult-line-multi)          ;; ne
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s"               . consult-history)
         ("M-r"               . consult-history)
         :map org-mode-map
         ("M-g o"             . consult-org-heading))


  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  :hook (completion-list-mode . consult-preview-at-point-mode)

  ;; The :init configuration is always executed (Not lazy)
  :init

  ;; Optionally configure the register formatting. This improves the register
  ;; preview for `consult-register', `consult-register-load',
  ;; `consult-register-store' and the Emacs built-ins.
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)

  ;; Optionally tweak the register preview window.
  ;; This adds thin lines, sorting and hides the mode line of the window.
  (advice-add #'register-preview :override #'consult-register-window)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config

  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key "M-.")
  ;; (setq consult-preview-key '("S-<down>" "S-<up>"))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<")) ;; "C-+"

;; Optionally make narrowing help available in the minibuffer.
;; You may want to use `embark-prefix-help-command' or which-key instead.
;; (define-key consult-narrow-map (vconcat consult-narrow-key "?") #'consult-narrow-help)

;; By default `consult-project-function' uses `project-root' from project.el.
;; Optionally configure a different project root function.
  ;;;; 1. project.el (the default)
;; (setq consult-project-function #'consult--default-project--function)
  ;;;; 2. vc.el (vc-root-dir)
;; (setq consult-project-function (lambda (_) (vc-root-dir)))
  ;;;; 3. locate-dominating-file
;; (setq consult-project-function (lambda (_) (locate-dominating-file "." ".git")))
  ;;;; 4. projectile.el (projectile-project-root)
;; (autoload 'projectile-project-root "projectile")
;; (setq consult-project-function (lambda (_) (projectile-project-root)))
  ;;;; 5. No project support
;; (setq consult-project-function nil)


(use-package embark
  :ensure t

  :bind
  (("C-." . embark-act)         ;; pick some comfortable binding
   ("C-;" . embark-dwim)        ;; good alternative: M-.
   ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'

  :init

  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  ;; Show the Embark target at point via Eldoc.  You may adjust the Eldoc
  ;; strategy, if you want to see the documentation from multiple providers.
  (add-hook 'eldoc-documentation-functions #'embark-eldoc-first-target)
  ;; (setq eldoc-documentation-strategy #'eldoc-documentation-compose-eagerly)

  :config

  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

(use-package embark-consult
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package toc-org
  :after (org)
  :commands toc-org-enable
  :hook (org-mode-hook . toc-org-enable))

(use-package org-modern
  :hook (org-mode-hook . org-modern-mode)
  :config (set-face-attribute 'org-modern-symbol nil :family "Iosevka"))

(use-package parinfer-rust-mode
  :custom (parinfer-rust-auto-download t)
  :hook emacs-lisp-mode)

(use-package format-all
  :custom (format-all-show-errors 'warnings)
  :hook (prog-mode-hook . format-all-ensure-formatter))

(use-package editorconfig
  :config (editorconfig-mode 1))

(use-package helpful
  :bind (("C-h f" . helpful-callable)
         ("C-h v" . helpful-variable)
         ("C-h k" . helpful-key)
         ("C-h x" . helpful-command)
         ("C-h F" . helpful-function)
         ("C-h C" . helpful-command)
         ("C-c C-d" . helpful-at-point)))

;;; TODO
;;; Git-Gutter
;;; https://ianyepan.github.io/posts/emacs-git-gutter/
;;; Ergoemacs
;;; Whitespace
;;; Fix tab spacing
;;; aliases: (defalias 'f 'foo-command) https://www.wilkesley.org/~ian/xah/emacs/emacs_alias.html
;;; Folding? seems hard
;;; tree-sitter https://www.masteringemacs.org/article/how-to-get-started-tree-sitter

;;; init.el ends here

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("e93c4567f5d30365064747972b179e80939cee875627034dc76cd50477c6b998" "d6e59d5d3e1e4ec825322deed1e154251abecff0b2bb6d32ac62b117f623bd50" default))
 '(package-selected-packages
   '(autumn-light-theme toc-org which-key parinfer-rust-mode org-superstar org-bullets all-the-icons-completion all-the-icons counsel ivy use-package org))
 '(tool-bar-mode nil)
 '(warning-suppress-types '((emacs))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "Iosevka NF Medium" :foundry "outline" :slant normal :weight medium :height 110 :width normal)))))
;; custom-set-faces was added by Custom.
;; If you edit it by hand, you could mess it up, so be careful.
;; Your init file should contain only one such instance.
;; If there is more than one, they won't work right.
