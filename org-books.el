;;; org-books.el --- Org Books, a paperless book like experience in emacs  -*- lexical-binding: t; -*-

;; Copyright (C) 2017 Aqeel Akber

;; Author:  Aqeel Ahmad Akber (AdmiralAkber)
;; Keywords: convenience, wp, outlines

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This software is licenced as AGPLv3

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Commentary
;;
;; TODO:
;;  [] Make Collection README's automatically useful
;;  [] Make collection mode auto insert header only work on files in
;;     collection folders.
;;  [] Make the #+DATE of Log's update every time it is saved
;;  [] Add subgroups for defcustom
;;  [] org-books-library-books defcustom gui broken if already defined

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Code:
(require 'org)

;;; -----------
;;; ORG BOOKS !
;;; -----------

;;; customizable variables
;; ---------------------------------------------------------------------

(defgroup orgbooks nil "Customizable variables for Org Books")

;; ---------------------------------------------------------------------

(defcustom org-books-git-enable nil
  "Use git integration RECOMMENDED. Will git commit each file save."
  :type 'boolean
  :group 'orgbooks)

;; ---------------------------------------------------------------------

(defcustom org-books-git-push nil
  "Push to remote git repository upon closing file."
  :type 'boolean
  :group 'orgbooks)

;; ---------------------------------------------------------------------

(defcustom org-books-library-dir "~/org"
  "The base directory of the Org Books library"
  :type 'directory
  :group 'orgbooks)

;; ---------------------------------------------------------------------

(defcustom org-books-library-books nil
  "Books in your library. Make as many as you want, they're free!

DIRECTORY
Pages stored in folder relative to `org-books-library-dir'.

    Recommended syntax: Name/Subvol/Subsubvol

              Examples: personal, personal/projects 
                        articles/physics, articles/media
                        phd, phd/theory, phd/experiment

BOOK TYPE
Defines the workflow by the way the pages are created.

       Journal: Many files, one per calendar day.
           Log: One file, hierarchial headline by date.
    Collection: Just a folder, pages are user managed.

Journals are best used for frequent and large brain/information
dumps that you won't visit frequently. Logs are datetrees, more
suitable for small snippets of information, thoughts, and GTD in
long term projects. Collections are good for novels,
publications, dumps, essays, creative projects, research,
anything that takes a really long time and requires more workflow
freedom.

Different types in subvolumes can be used to provide a more
complete workflow for a given topic. An example structure for
academic research is a log for the top level book for GTD and
scrap thoughts, multiple subvolumes can be made as collections
for each idea worth going down the rabbit hole for. Using header
tags in logs that are correlated with the collection is
recommended.

ADD TO AGENDA
If true, will add this book to the `org-agenda-files' list.

ADDITIONAL NOTES: 
As a Log is just a specific file in a folder, it can actually
share a directory with collections and journals. However, if the
journal or collection is being added to the agenda this will also
add the log to the agenda."
  :type '(alist :key-type directory
		:value-type (group
			     (radio :tag "Book type"
				    (const :tag "Journal" "J")
				    (const :tag "Log" "L")
				    (const :tag "Collection" "C"))
			     (boolean :inline t :tag "Add to agenda" t)))
  :group 'orgbooks)

;; ---------------------------------------------------------------------

(defcustom org-books-user-author "Anonymous"
  "Author name that will be appended to all pages"
  :type 'string
  :group 'orgbooks)

;; ---------------------------------------------------------------------

(defcustom org-books-journal-auto-header t
  "Auto insertion of a header in journal files STRONGLY RECOMMENDED."
  :type 'boolean
  :group 'orgbooks)

;; ---------------------------------------------------------------------

(defcustom org-books-journal-capture t
  "Add a org capture templates for journals. See `org-capture'"
  :type 'boolean
  :group 'orgbooks)

;; ---------------------------------------------------------------------

(defcustom org-books-log-auto-header t
  "Auto insertion/updating of a header in log files STRONGLY RECOMMENDED."
  :type 'boolean
  :group 'orgbooks)

;; ---------------------------------------------------------------------

(defcustom org-books-log-capture t
  "Add org capture templates for logs STRONGLY RECOMMENDED. See `org-capture'"
  :type 'boolean
  :group 'orgbooks)

;; ---------------------------------------------------------------------

(defcustom org-books-collection-auto-header t
  "Auto insertion/updating of a header in collection files STRONGLY RECOMMENDED."
  :type 'boolean
  :group 'orgbooks)

;; ---------------------------------------------------------------------
;;; end customizable variables


;;; functions
;; ---------------------------------------------------------------------

(defun org-books--get-books ()
  "Returns list of book names from `org-books-library-books'"
  (let ((res ()))
    (dolist (x org-books-library-books)
	(push (car x) res))
    (nreverse res)))

;; ---------------------------------------------------------------------

(defun org-books--get-books-of-type (type &optional prefix suffix fn)
  "Returns list of book names from `org-books-library-books' if
their type identifier matches the first argument.

OPTIONAL 
    prefix (string): adds this string before returned name
    suffix (string): adds this string after the returned name
    fn (boolean): turns book/subvol into book-subvol.org and adds after suffix"
  (let ((res ()))
    (dolist (x org-books-library-books)
      (when (equal type (car (cdr x)))
	(push (concat
	       prefix
	       (car x)
	       suffix
	       (when (eq t fn)
		 (concat
		  (dired-replace-in-string "/" "-" (car x))
		  ".org")))
	      res)))
    (nreverse res)))

;; ---------------------------------------------------------------------

(defun org-books--get-books-of-type-in-agenda (type &optional prefix suffix fn)
  "As per `org-books--get-books-of-type' but only returns book names
that are flagged to be added to the org agenda. 

OPTIONAL 
    prefix (string): adds this string before returned name
    suffix (string): adds this string after the returned name
    fn (boolean): turns book/subvol into book-subvol.org and adds after suffix"
  (let ((res ()))
    (dolist (x org-books-library-books)
      (when (and (equal type (car (cdr x))) (equal t (cdr (cdr x))))
	(push (concat
	       prefix
	       (car x)
	       suffix
	       (when (eq t fn)
		 (concat
		  (dired-replace-in-string "/" "-" (car x))
		  ".org")))
	      res)))
    (nreverse res)))

;; ---------------------------------------------------------------------
;;; end functions

;;; --------------------
;;; BOOK TYPE: JOURNAL !
;;; --------------------

;;; variables
;; ---------------------------------------------------------------------

(setq org-books--j-capture-templates
      '(
	;; ...
	("j" "Journal Note"
	 entry (file (call-interactively 'org-books--j-file-today) )
	 "* Capture Entry\n%?\nFrom: %a"
	 :empty-lines 1)
	;; ..
	))

;; ---------------------------------------------------------------------
;;; end variables

;;; functions
;; ---------------------------------------------------------------------

(defun org-books--j-file-today (book)
  "Return today's page location for a journal like book."
  (interactive (list
		(completing-read "Journal: "
				 (org-books--get-books-of-type "J"))))
  (expand-file-name
   (concat
    org-books-library-dir
    "/"
    book
    "/J"
    (format-time-string "%Y%m%d")
    ".org")))

;; ---------------------------------------------------------------------

(defun org-books-j-page-date ()
  "Returns the journal's page date. Extracted from the filename."
  (when (string-match
	 "\\(J\\)\\(20[0-9][0-9]\\)\\([0-9][0-9]\\)\\([0-9][0-9]\\)\\(.org\\)"
	 (buffer-name))
    (let ((year  (string-to-number (match-string 2 (buffer-name))))
          (month (string-to-number (match-string 3 (buffer-name))))
          (day   (string-to-number (match-string 4 (buffer-name))))
          (datim nil))
      (setq datim (encode-time 0 0 0 day month year))
      (format-time-string "%Y-%m-%d (%A)" datim))))

;; ---------------------------------------------------------------------

(defun org-books/j-today ()
  "Open a journal to today's page"
  (interactive)
  (find-file (call-interactively 'org-books--j-file-today))
  (org-books/journal-mode))

;; ---------------------------------------------------------------------
;;; end functions

;;; minor mode
;; ---------------------------------------------------------------------

(define-minor-mode org-books/journal-mode
  "Org Books Journal"
  :lighter " OB:J"
  :group 'orgbooks
  (when (eq t org-books-git-push)
    (set (make-variable-buffer-local 'gac-automatically-push-p) t)))

;; ---------------------------------------------------------------------

(defun org-books--auto-journal-mode ()
    "Enables journal mode for org-books Journal files"
  (when
      (and
	 (string-match
	 "\\(J\\)\\(20[0-9][0-9]\\)\\([0-9][0-9]\\)\\([0-9][0-9]\\)\\(.org\\)"
	 (buffer-name))
	 (not (eq nil
		  (car (member
			(file-name-directory buffer-file-name)
			(org-books--get-books-of-type "J"
						      (concat (expand-file-name org-books-library-dir) "/")
						      "/"
						      nil))))))
    (org-books/journal-mode)))

;; ---------------------------------------------------------------------
;;; end minor mode

;;; ----------------
;;; BOOK TYPE: LOG !
;;; ----------------

(require 'org-datetree)

;;; variables
;; ---------------------------------------------------------------------

(setq org-books--l-capture-templates
      '(
	;; ...
	("l" "Log entry"
	 entry (file+datetree (call-interactively 'org-books--l-file))
	 "**** %U Re: %? %^g \nFrom: %a"
	 :empty-lines 1)
	;; ..
	("t" "Log TODO item"
	 entry (file+datetree (call-interactively 'org-books--l-file) )
	 "**** TODO %^{Task description} %^g \n DEADLINE: <%<%Y-%m-%d %a>>\n%?\nAdded: %U\nFrom: %a"
	 :empty-lines 1)
	;; ..
	))

;; ---------------------------------------------------------------------
;;; end variables

;;; functions
;; ---------------------------------------------------------------------

(defun org-books--l-goto-date (y m d)
  "Goes to datetree entry for date: YEAR MONTH DAY"
  (org-datetree-find-date-create (list m d y)))

;; ---------------------------------------------------------------------

(defun org-books--l-goto-today ()
  "Creates or goes to the datetree entry for today in current file."
  (interactive)
  (let ((y (string-to-int (format-time-string "%Y")))
	(m (string-to-int (format-time-string "%m")))
	(d (string-to-int (format-time-string "%d"))))
    (org-books--l-goto-date y m d)))
  
;; ---------------------------------------------------------------------

(require 'dired)
(defun org-books--l-file (book)
  "Return location of a logbook."
  (interactive (list
		(completing-read "Logbook: "
				 (org-books--get-books-of-type "L"))))
  (expand-file-name
   (concat
    org-books-library-dir
    "/"
    book
    "/LOG-"
    (dired-replace-in-string "/" "-" book)
    ".org")))

;; ---------------------------------------------------------------------

(defun org-books/l-today()
  "Open a log to today's page"
  (interactive)
  (find-file (call-interactively 'org-books--l-file))
  (org-books/log-mode)
  (org-books--l-goto-today))

;; ---------------------------------------------------------------------
;;; end functions

;;; minor mode
;; ---------------------------------------------------------------------

(define-minor-mode org-books/log-mode
  "Org Books Log"
  :lighter " OB:L"
  :group 'orgbooks
  (when (eq t org-books-git-push)
    (set (make-variable-buffer-local 'gac-automatically-push-p) t)))


;; ---------------------------------------------------------------------

(defun org-books--auto-log-mode ()
    "Enables log mode for org-books Log files"
  (when
      (not (eq nil
	       (car (member
		     (buffer-file-name)
		     (org-books--get-books-of-type "L"
						   (concat (expand-file-name org-books-library-dir) "/")
						   "/LOG-"
						   t)))))
    (org-books/log-mode)))

;; ---------------------------------------------------------------------
;;; end minor mode


;;; -----------------------
;;; BOOK TYPE: COLLECTION !
;;; -----------------------

;;; functions
;; ---------------------------------------------------------------------

(defun org-books--c-file (book)
  "Return location of a collection."
  (interactive (list
		(completing-read "Collection: "
				 (org-books--get-books-of-type "C"))))
  (expand-file-name
   (concat
    org-books-library-dir
    "/"
    book
    "/README.org")))

;; ---------------------------------------------------------------------

(defun org-books/c-open()
  "Open a collection to its readme"
  (interactive)
  (find-file (call-interactively 'org-books--c-file))
  (org-books/collection-mode))

;; ---------------------------------------------------------------------
;;; end functions

;;; minor mode
;; ---------------------------------------------------------------------

(define-minor-mode org-books/collection-mode
  "Org Books Collection"
  :lighter " OB:C"
  :group 'orgbooks
  (when (eq t org-books-git-push)
    (set (make-variable-buffer-local 'gac-automatically-push-p) t)))    

;; ---------------------------------------------------------------------

(defun org-books--auto-collection-mode ()
  "Enables collection mode for files in org-books Collections"
  (when
      (not (eq nil
	       (car (member
		     (file-name-directory buffer-file-name)
		     (org-books--get-books-of-type "C"
						   (concat (expand-file-name org-books-library-dir) "/")
						   "/"
						   nil)))))
    (org-books/collection-mode)))

;; ---------------------------------------------------------------------
;;; end minor mode

;; -----------
;; ORG BOOKS !
;; -----------

;;; setup
;; ---------------------------------------------------------------------

(defun org-books-init ()
  "Initializes Org Books"
  ;; =================
  ;; capture templates
  ;; =================
  (when (eq nil (boundp 'org-capture-templates))
    (setq org-capture-templates nil))

  (when (eq t org-books-log-capture)
    (setq org-capture-templates
	  (append org-capture-templates
		  org-books--l-capture-templates)))

  (when (eq t org-books-journal-capture)
    (setq org-capture-templates
	  (append org-capture-templates
		  org-books--j-capture-templates)))
  ;; =============
  ;; add to agenda
  ;; =============
  (when (eq nil (boundp 'org-agenda-files))
    (setq org-agenda-files nil))
  
  (setq org-agenda-files (append org-agenda-files
				 (org-books--get-books-of-type-in-agenda
				  "J"
				  (concat org-books-library-dir "/")
				  nil
				  nil)))
  
  (setq org-agenda-files (append org-agenda-files
				 (org-books--get-books-of-type-in-agenda
				  "L"
				  (concat org-books-library-dir "/")
				  "/LOG-"
				  t)))
  
  (setq org-agenda-files (append org-agenda-files
				 (org-books--get-books-of-type-in-agenda
				  "C"
				  (concat org-books-library-dir "/")   
				  nil
				  nil)))
  ;; ================
  ;; auto minor modes
  ;; ================
  (add-hook 'org-mode-hook 'org-books--auto-journal-mode)
  (add-hook 'org-mode-hook 'org-books--auto-log-mode)
  (add-hook 'org-mode-hook 'org-books--auto-collection-mode)
  ;; ===============  
  ;; git integration
  ;; ===============
  (when (eq t org-books-git-enable)
    (require 'git-auto-commit-mode)
    (add-hook 'org-books/journal-mode-hook 'git-auto-commit-mode)
    (add-hook 'org-books/log-mode-hook 'git-auto-commit-mode)
    (add-hook 'org-books/collection-mode-hook 'git-auto-commit-mode)
    )
  ;; ===================
  ;; auto insert headers
  ;; ===================
  (when (eq t org-books-journal-auto-header)
    (add-hook 'org-books/journal-mode-hook 'auto-insert)
    (eval-after-load 'autoinsert
      '(define-auto-insert
	 '("\\(J\\)\\(20[0-9][0-9]\\)\\([0-9][0-9]\\)\\([0-9][0-9]\\)\\(.org\\)" . "Org Books Journal")
	 '("Short description: "
	   "#+TITLE: Journal Entry - "
	   (car
	    (last
	     (split-string
	      (file-name-directory buffer-file-name)
	      (concat
	       (expand-file-name org-books-library-dir)
	       "/")))) \n
	       (concat
		"#+AUTHOR: " org-books-user-author) \n
		"#+DATE: " (org-books-j-page-date) \n
		"#+FILETAGS: "
		(car
		 (last
		  (split-string
		   (file-name-directory buffer-file-name)
		   (concat (expand-file-name org-books-library-dir)
			   "/")))) \n \n
			   > _ \n
			   ))))
  
  (when (eq t org-books-log-auto-header)
    (add-hook 'org-books/log-mode-hook 'auto-insert)
    (eval-after-load 'autoinsert
      '(define-auto-insert
	 '("\\(LOG-\\).+\\(.org\\)" . "Org Books Log")
	 '("Short description: "
	   "#+TITLE: Log Book - "
	   (car
	    (last
	     (split-string
	      (file-name-directory buffer-file-name)
	      (concat
	       (expand-file-name org-books-library-dir)
	       "/")))) \n
	       (concat
		"#+AUTHOR: " org-books-user-author) \n
	       "#+FILETAGS: "
	       (car
		(last
		 (split-string
		  (file-name-directory buffer-file-name)
		  (concat (expand-file-name org-books-library-dir)
			  "/")))) \n \n
			  > _ \n
			  ))))

  (when (eq t org-books-collection-auto-header)
    (add-hook 'org-books/collection-mode-hook 'auto-insert)
    (eval-after-load 'autoinsert
      '(define-auto-insert
	 '(".+\\(.org\\)" . "Org Books Collection")
	 '("Short description: "
	   "#+TITLE: Collection - "
	   (car
	    (last
	     (split-string
	      (buffer-file-name)
	      (concat
	       (expand-file-name org-books-library-dir)
	       "/")))) \n
	       (concat
		"#+AUTHOR: " org-books-user-author) \n
	       "#+DATE: " (format-time-string "%Y-%m-%d (%A)") \n
	       "#+FILETAGS: "
	       (car
		(last
		 (split-string
		  (buffer-file-name)
		  (concat (expand-file-name org-books-library-dir)
			  "/")))) \n \n
			  > _ \n
			  ))))
  ;; =============================================== end org-books-init
  )

;; ---------------------------------------------------------------------
;;; end setup

;;; minor mode
;; ---------------------------------------------------------------------

(define-minor-mode org-books
  "A paperless book like experience in emacs."
  :lighter " Books"
  :group 'orgbooks
  :global t
  :keymap (let ((map (make-sparse-keymap)))
	    (define-key map (kbd "C-c a") 'org-agenda)
	    (define-key map (kbd "C-c t") 'org-capture)
	    (define-key map (kbd "C-c C-l") 'org-store-link)
	    (define-key map (kbd "C-c j") 'org-books/j-today)
	    (define-key map (kbd "C-c l") 'org-books/l-today)
	    (define-key map (kbd "C-c c") 'org-books/c-open)
	    map)
  (org-books-init))

;; ---------------------------------------------------------------------
;;; end minor mode

(provide 'org-books)

;;; org-books.el ends here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
