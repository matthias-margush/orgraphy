;;; orgraphy.el --- Beautify markdown and org -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Matthias Margush <matthias.margush@gmail.com>

;; Author: Matthias Margush <matthias.margush@gmail.com>
;; URL: https://github.com/matthias-margush/orgraphy
;; Version: 0.0.1
;; Package-Requires: ((emacs "25.4.0"))
;; Keywords: theme, faces

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Beautify markdown and org.

;; See the README for more info:
;; https://github.com/matthias-margush/orgraphy

;;; Code:
(defun orgraphy--org-mode-faces ()
  "Set up faces for org mode."
  (orgraphy--set 'prettify-symbols-alist prettify-symbols-alist)
  (push '("#+TITLE:" . ?⋮) prettify-symbols-alist)
  (push '("#+begin_src" . ?λ) prettify-symbols-alist)
  (push '("#+BEGIN_SRC" . ?λ) prettify-symbols-alist)
  (push '("#+end_src" . ?≋) prettify-symbols-alist)
  (push '("#+END_SRC" . ?≋) prettify-symbols-alist)
  (push '("#+begin_quote" . ?“) prettify-symbols-alist)
  (push '("#+BEGIN_QUOTE" . ?“) prettify-symbols-alist)
  (push '("#+end_quote" . ?”) prettify-symbols-alist)
  (push '("#+END_QUOTE" . ?”) prettify-symbols-alist)
  (prettify-symbols-mode)

  ;;  Configure faces
  (orgraphy--faces)

  ;; Hide bullets
  (font-lock-add-keywords
   nil
   '(("^\\(\\*+ \\).*$"
      (0
       (prog1 nil
         (let ((beg (match-beginning 1))
               (end (match-end 1))
               (line (match-string 0)))
           (when (and line (not (string-match-p org-todo-regexp line)))
             (put-text-property beg end
                                'invisible t))))))))

  ;; Ensure todo lines aren't rendered as headings
  (let ((keyword-faces (or (when (boundp 'org-todo-keyword-faces) org-todo-keyword-faces)
                         '(("TODO" . org-todo)
                           ("DONE" . org-done)))))
    (dolist (keyword-face keyword-faces)
      (let ((keyword (car keyword-face))
            (face (cdr keyword-face)))
        (font-lock-add-keywords
         nil
         `((,(concat "^\*+ " keyword ".*$")
            (0
             (prog1 nil
               (set-text-properties (match-beginning 0)
                                    (match-end 0)
                                    '(face default)))))))
        (font-lock-add-keywords
         nil
         `((,(concat "^\*+ \\(" keyword "\\).*$")
            (1
             (prog1 nil
               (set-text-properties (match-beginning 0)
                                    (match-end 0)
                                    '(face ,face)))))))))))

(defvar orgraphy--original-faces (make-hash-table)
  "Original faces.")

(defvar orgraphy--original-syms (make-hash-table)
  "Original syms.")

(defun orgraphy--faces ()
  "Set up faces."
  (orgraphy--set 'markdown-header-scaling t)
  (orgraphy--set 'org-pretty-entities t)
  (orgraphy--set 'org-hide-leading-stars nil)
  (orgraphy--set 'org-hide-emphasis-markers t)
  (orgraphy--set 'org-fontify-done-headline t)
  (orgraphy--set 'org-src-fontify-natively t)
  (orgraphy--set 'org-adapt-indentation nil)
  (orgraphy--set 'org-fontify-quote-and-verse-blocks t)
  (orgraphy--set 'org-fontify-whole-heading-line nil)

  (orgraphy--set-face-attribute 'helm-source-header nil :inherit 'variable-pitch :height 1.6 :weight 'normal :underline nil)
  (orgraphy--set-face-attribute 'magit-section-heading nil :height 1.5 :inherit 'variable-pitch :weight 'normal)
  (orgraphy--set-face-attribute 'magit-section-heading-selection nil :inherit 'variable-pitch)
  (orgraphy--set-face-attribute 'org-document-info-keyword nil :height 0.7)
  (orgraphy--set-face-attribute 'org-document-title nil :height 2.6 :inherit 'variable-pitch :weight 'normal)
  (orgraphy--set-face-attribute 'org-meta-line nil :height 0.7)
  (orgraphy--set-face-attribute 'org-property-value nil :height 0.65)
  (orgraphy--set-face-attribute 'org-special-keyword nil :height 0.65)
  (orgraphy--set-face-attribute 'markdown-header-face nil :inherit 'variable-pitch :weight 'normal)
  (orgraphy--set-face-attribute 'outline-1 nil :height 2.0 :inherit 'variable-pitch :weight 'normal)
  (orgraphy--set-face-attribute 'outline-2 nil :height 1.6 :inherit 'variable-pitch :weight 'normal)
  (orgraphy--set-face-attribute 'outline-3 nil :height 1.4 :inherit 'variable-pitch :weight 'normal)
  (orgraphy--set-face-attribute 'outline-4 nil :height 1.2 :inherit 'variable-pitch :weight 'normal)
  (orgraphy--set-face-attribute 'outline-5 nil :height 1.0 :inherit 'variable-pitch :weight 'bold :slant 'italic)
  (orgraphy--set-face-attribute 'outline-6 nil :height 1.0 :inherit 'variable-pitch :weight 'bold :slant 'italic)
  (orgraphy--set-face-attribute 'outline-7 nil :height 1.0 :inherit 'variable-pitch :weight 'bold :slant 'italic)
  (orgraphy--set-face-attribute 'outline-8 nil :height 1.0 :inherit 'variable-pitch :weight 'bold :slant 'italic)
  (orgraphy--set-face-attribute 'markup-gen-face nil :inherit 'variable-pitch :weight 'normal) )

(defun orgraphy--set-face-attribute (face frame &rest args)
  "Set attributes of FACE on FRAME from ARGS."
  (when (facep face)
    (unless (gethash face orgraphy--original-faces)
        (puthash face (face-all-attributes face) orgraphy--original-faces))
    (apply #'set-face-attribute face frame args)))

(defun orgraphy--set (sym val)
  "Set SYM to VAL."
  (when (boundp sym)
    (unless (gethash sym orgraphy--original-syms)
      (puthash sym val orgraphy--original-syms))
    (set sym val)))

(defun orgraphy--init ()
  "Initialize orgraphy."
  (add-hook 'org-mode-hook #'orgraphy--org-mode-faces)
  (orgraphy--faces))

(defun orgraphy--deinit ()
  "Deinitialize orgraphy."
  (remove-hook 'org-mode-hook #'orgraphy--org-mode-faces)
  (maphash (lambda (face attributes)
             (dolist (attr attributes)
               (let ((attr-name (car attr))
                     (attr-value (cdr attr)))
                 (set-face-attribute face nil attr-name attr-value))))
           orgraphy--original-faces)
  (maphash (lambda (sym val)
             (set sym val))
           orgraphy--original-syms))

;;;###autoload
(define-minor-mode orgraphy-mode
  "Toggle 'orgraphy mode'.

  This global minor mode provides a tab-like bar for workspaces."
  :global t
  (if orgraphy-mode
      (orgraphy--init)
    (orgraphy--deinit)))

(provide 'orgraphy)

;;; orgraphy.el ends here
