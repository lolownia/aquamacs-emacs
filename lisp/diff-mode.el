;; GNU Emacs is free software; you can redistribute it and/or modify
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.
;; - Refine hunk on a word-by-word basis.
;; 
  "*Non-nil means `diff-goto-source' jumps to the old file.

    ("\C-c\C-r" . diff-reverse-direction)
    ("\C-c\C-w" . diff-refine-hunk)
    ["Jump to Source"		diff-goto-source	t]
    ["Apply hunk"		diff-apply-hunk		t]
    ["Test applying hunk"	diff-test-hunk		t]
    ["Apply diff with Ediff"	diff-ediff-patch	t]
    ["Reverse direction"	diff-reverse-direction	t]
    ["Context -> Unified"	diff-context->unified	t]
    ["Unified -> Context"	diff-unified->context	t]
    ["Split hunk"		diff-split-hunk		t]
    ["Refine hunk"	        diff-refine-hunk	t]
    ["Kill current hunk"	diff-hunk-kill   	t]
    ["Kill current file's hunks" diff-file-kill   	t]
    ["Previous Hunk"		diff-hunk-prev  	t]
    ["Next Hunk"		diff-hunk-next  	t]
    ["Previous File"		diff-file-prev  	t]
    ["Next File"		diff-file-next  	t]
     :background "grey85")
    ("^--- .+ ----$"             . diff-hunk-header-face) ;context
    ("^\\(---\\|\\+\\+\\+\\|\\*\\*\\*\\) \\(\\S-+\\)\\(.*[^*-]\\)?\n"
     (0 diff-header-face) (2 diff-file-header-face prepend))
(defconst diff-file-header-re (concat "^\\(--- .+\n\\+\\+\\+ \\|\\*\\*\\* .+\n--- \\|[^-+!<>0-9@* ]\\).+\n" (substring diff-hunk-header-re 1)))
      (unless style
        ;; Especially important for unified (because headers are ambiguous).
        (setq style (cdr (assq (char-after) '((?@ . unified) (?* . context))))))
    (forward-line 2)
    (condition-case ()
	(re-search-backward diff-file-header-re)
      (error (error "Can't find the beginning of the file")))))
 diff-hunk diff-hunk-header-re "hunk" diff-end-of-hunk diff-restrict-view)
(defconst diff-file-junk-re "diff \\|index ") ; "index " is output by git-diff.
  (let ((orig (point))
        ;; Skip forward over what might be "leading junk" so as to get
        ;; closer to the actual diff.
        (_ (progn (beginning-of-line)
                  (while (looking-at diff-file-junk-re)
                    (forward-line 1))))
        (start (point))
        (file (condition-case err (progn (diff-beginning-of-file) (point))
                (error err)))
        ;; prevhunk is one of the limits.
        (prevhunk (save-excursion (ignore-errors (diff-hunk-prev) (point))))
        err)
    (when (consp file)
      ;; Presumably, we started before the file header, in the leading junk.
      (setq err file)
      (diff-file-next)
      (setq file (point)))
    (let ((index (save-excursion
                   (forward-line 1)  ;In case we're looking at "Index:".
                   (re-search-backward "^Index: " prevhunk t))))
      (when index (setq file index))
      (if (<= file start)
            (goto-char file)
        ;; File starts *after* the starting point: we really weren't in
        ;; a file diff but elsewhere.
        (goto-char orig)
        (signal (car err) (cdr err))))))
(defun diff-find-file-name (&optional old prefix)
	    (diff-find-file-name old (match-string 1)))
		  (lines2 (or (match-string 7) "1")))
					    -1)) " ****"))
						 -1)) " ----\n" hunk))
                          (?\n (insert "  ") (setq modif nil) (backward-char 2))
			    (setq delete nil)))))))))))))))
	  (inhibit-read-only t))
	(goto-char start)
	(while (and (re-search-forward "^\\(\\(\\*\\*\\*\\) .+\n\\(---\\) .+\\|\\*\\{15\\}.*\n\\*\\*\\* \\([0-9]+\\),\\(-?[0-9]+\\) \\*\\*\\*\\*\\)$" nil t)
		    (< (point) end))
	  (combine-after-change-calls
	    (if (match-beginning 2)
		;; we matched a file header
		(progn
		  ;; use reverse order to make sure the indices are kept valid
		  (replace-match "+++" t t nil 3)
		  (replace-match "---" t t nil 2))
	      ;; we matched a hunk header
	      (let ((line1s (match-string 4))
		    (line1e (match-string 5))
		    (pt1 (match-beginning 0)))
		(replace-match "")
		(unless (re-search-forward
			 "^--- \\([0-9]+\\),\\(-?[0-9]+\\) ----$" nil t)
		  (error "Can't find matching `--- n1,n2 ----' line"))
		(let ((line2s (match-string 1))
		      (line2e (match-string 2))
		      (pt2 (progn
			     (delete-region (progn (beginning-of-line) (point))
					    (progn (forward-line 1) (point)))
			     (point-marker))))
		  (goto-char pt1)
		  (forward-line 1)
		  (while (< (point) pt2)
		    (case (char-after)
		      ((?! ?-) (delete-char 2) (insert "-") (forward-line 1))
		      (?\s     ;merge with the other half of the chunk
		       (let* ((endline2
			       (save-excursion
				 (goto-char pt2) (forward-line 1) (point)))
			      (c (char-after pt2)))
			 (case c
			   ((?! ?+)
			    (insert "+"
				    (prog1 (buffer-substring (+ pt2 2) endline2)
				      (delete-region pt2 endline2))))
			   (?\s		;FIXME: check consistency
			    (delete-region pt2 endline2)
			    (delete-char 1)
			    (forward-line 1))
			   (?\\ (forward-line 1))
			   (t (delete-char 1) (forward-line 1)))))
		      (t (forward-line 1))))
		  (while (looking-at "[+! ] ")
		    (if (/= (char-after) ?!) (forward-char 1)
		      (delete-char 1) (insert "+"))
		    (delete-char 1) (forward-line 1))
		  (save-excursion
		    (goto-char pt1)
		    (insert "@@ -" line1s ","
			    (number-to-string (- (string-to-number line1e)
						 (string-to-number line1s)
						 -1))
			    " +" line2s ","
			    (number-to-string (- (string-to-number line2e)
						 (string-to-number line2s)
						 -1)) " @@")))))))))))
		  (unless (looking-at "^--- \\([0-9]+,-?[0-9]+\\) ----$")
		  (let ((str1 (match-string 1)))
		    (replace-match lines1 nil nil nil 1)
	     ((looking-at "--- \\([0-9]+\\),\\([0-9]*\\) ----$")
	;; We used to fixup modifs on all the changes, but it turns out
	;; that it's safer not to do it on big changes, for example
	;; when yanking a big diff, since we might then screw up perfectly
	;; correct values.  -stef
	;; (unless (ignore-errors
	;; 	  (diff-beginning-of-hunk)
	;; 	  (save-excursion
	;; 	    (diff-end-of-hunk)
	;; 	    (> (point) (car diff-unhandled-changes))))
	;;   (goto-char (car diff-unhandled-changes))
	;; (re-search-forward diff-hunk-header-re (cdr diff-unhandled-changes))
	;;   (diff-beginning-of-hunk))
	;; (diff-fixup-modifs (point) (cdr diff-unhandled-changes))
	(when (save-excursion
		(>= (point) (cdr diff-unhandled-changes)))
    (setq diff-unhandled-changes nil)))
        (if (not (looking-at "\\*\\{15\\}\\(?: .*\\)?\n\\*\\*\\* \\([0-9]+\\),\\([0-9]+\\) \\*\\*\\*\\*"))
           (1+ (- (string-to-number (match-string 2))
                  (string-to-number (match-string 1)))))
          (if (not (looking-at "--- \\([0-9]+\\),\\([0-9]+\\) ----$"))
             (1+ (- (string-to-number (match-string 2))
                    (string-to-number (match-string 1))))))))
	     (re-search-forward "^--- " nil t)
(defsubst diff-xor (a b) (if a (not b) b))
		       (unless (re-search-forward "^--- \\([0-9,]+\\)" nil t)
      ;; If REVERSE go to the new file, otherwise go to the old.
      (diff-find-source-location (not reverse) reverse)
      ;; If REVERSE go to the new file, otherwise go to the old.
      (diff-find-source-location (not reverse) reverse)
		(funcall (with-current-buffer buf major-mode))
(defun diff-refine-hunk ()
  "Refine the current hunk by ignoring space differences."
	 (inhibit-read-only t)