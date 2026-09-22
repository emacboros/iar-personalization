;;; fork-parse-walk.el --- read-walk a file, print explicit verdict.
;; c238: the belt's walker, extracted. The reader is the truth.
;; LIMITATION (found by negative test, c238): the elisp reader RECOVERS
;; from a truncated file -- an unbalanced OPEN form raises `end-of-file'
;; at point-max, indistinguishable from healthy EOF. The reader catches
;; mid-file imbalance (extra close, stray text) but not truncation.
;; Truncation is the git layer's job: `git status' on the fork shows a
;; modified file, and the belt's caller compares against backups.
(let ((file (car (last command-line-args))))
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let ((forms 0) (err nil))
      (condition-case e
          (while t
            (read (current-buffer))
            (setq forms (1+ forms)))
        (end-of-file (setq err nil))
        (error (setq err (format "%s at pos %d" (cdr e) (point)))))
      (if err
          (princ (format "PARSE-ERR %s: %s" file err))
        (princ (format "PARSE-OK %s forms=%d" file forms)))))
  (princ "\n"))
