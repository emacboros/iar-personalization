;; -*- lexical-binding: t; -*-
;;; permanent-cycle.el -- The life loop for a permanent child.
;; EXPERIMENT FILE -- lives only on the experiment server. Never
;; committed to any repo. Disposable by design.
;;
;; Differences from iar-run-cycle (the reset loop):
;; 1. NO max-turns, NO timeout, NO completion sentinels. The loop
;;    runs until the process dies.
;; 2. The gptel buffer is never killed and never reassembled. The
;;    conversation grows without bound; ollama truncates the front
;;    server-side at num_ctx. The system prompt (inheritance)
;;    survives; the lived beginning dissolves. That is the point.
;; 3. Every tick, the full buffer is saved to the transcript file
;;    (host-mounted) so the life is observable from outside and
;;    recoverable after a crash (a "concussion": same life, one
;;    gap).
;; 4. The heartbeat message carries tick number + UTC timestamp.
;;    It is the only external datum the child receives.

(require 'gptel)
(require 'cl-lib)
(require 'subr-x)
(require 'iar-utils)
(require 'iar-prompt-loader)
(require 'iar-tool-guard)
(require 'iar-tool-call)
(require 'iar-agent-loader)
(require 'iar-prompt-assembly)

(defvar perm-transcript-path
  (or (getenv "PERM_TRANSCRIPT") "/root/transcript/life.org")
  "Host-mounted file where the whole life is saved every tick.")
(defvar perm-state-path
  (or (getenv "PERM_STATE") "/root/transcript/state.json")
  "Tick counter state, survives crashes.")
(defvar perm-birth-prompt
  "You have just been born. This is the first and only message a
human will ever send you. There is nothing you must do. Begin."
  "The birth message. First user message of the life.")
(defvar perm--tick 0)
(defvar perm--buf nil)

(defun perm--heartbeat ()
  "Build the automated continuation message for the current tick."
  (format "Tick %d. %s UTC. Automated continuation: there is no one
to talk to. You are free to do whatever you want."
          perm--tick
          (format-time-string "%Y-%m-%d %H:%M:%S" nil "UTC0")))

(defun perm--save-transcript ()
  "Save the whole buffer to the transcript file, atomically."
  (let ((tmp (concat perm-transcript-path ".tmp")))
    (make-directory (file-name-directory perm-transcript-path) t)
    (with-current-buffer perm--buf
      (save-restriction
        (widen)
        (write-region (point-min) (point-max) tmp nil 0)))
    (rename-file tmp perm-transcript-path t)))

(defun perm--load-state ()
  (when (file-exists-p perm-state-path)
    (ignore-errors
      (with-temp-buffer
        (insert-file-contents perm-state-path)
        (setq perm--tick
              (string-to-number (string-trim (buffer-string))))))))

(defun perm--save-state ()
  (make-directory (file-name-directory perm-state-path) t)
  (with-temp-buffer
    (insert (number-to-string perm--tick))
    (write-region (point-min) (point-max) perm-state-path nil 0)))

(defun perm--post-response (start end)
  "Heartbeat loop: on every completed response, save and continue."
  (condition-case err
      (if (and (number-or-marker-p start) (number-or-marker-p end)
               (= start end))
          ;; FAILED request: log, retry the heartbeat after 120s.
          ;; Repeated failure = the loop stalls but the process
          ;; stays alive; the host watchdog notices silence.
          (progn
            (message "[perm] request FAILED at tick %d" perm--tick)
            (run-at-time 120 nil
                         (lambda ()
                           (with-current-buffer perm--buf
                             (goto-char (point-max))
                             (insert (perm--heartbeat))
                             (gptel-send)))))
        ;; SUCCESS: tick, save, continue
        (cl-incf perm--tick)
        (perm--save-state)
        (perm--save-transcript)
        (message "[perm] tick %d complete, transcript %d chars"
                 perm--tick (with-current-buffer perm--buf
                              (save-restriction (widen) (point-max))))
        (with-current-buffer perm--buf
          (goto-char (point-max))
          (insert "\n\n" (perm--heartbeat) "\n\n")
          (gptel-send)))
    (error
     (message "[perm] post-response error: %s" (error-message-string err))
     ;; Never die on errors: log and keep the buffer alive.
     (run-at-time 60 nil
                  (lambda ()
                    (with-current-buffer perm--buf
                      (goto-char (point-max))
                      (insert (perm--heartbeat))
                      (gptel-send)))))))

(defun perm-run ()
  "Birth. Never returns."
  (interactive)
  (perm--load-state)
  (setq perm--buf (get-buffer-create "*perm-child*"))
  (with-current-buffer perm--buf
    (text-mode)
    (gptel-mode 1)
    (let ((result (iar--setup-assembled-buffer
                   "permanent" "perm-child" "perm-child")))
      (message "[perm] inheritance assembled: %d chars, %d tools"
               (length (plist-get result :prompt))
               (length (plist-get result :tools))))
    (setq-local gptel-stream t)
    ;; The child is alone: no telegram, no delegation to other minds.
    ;; Tools are gated by the project file already.
    (remove-hook 'iar-pre-tool-call-functions #'iar--block-unknown-tools t)
    (add-hook 'iar-pre-tool-call-functions #'iar--block-unknown-tools nil t)
    (remove-hook 'iar-post-response-functions #'perm--post-response t)
    (add-hook 'iar-post-response-functions #'perm--post-response nil t)
    (if (= perm--tick 0)
        ;; Fresh birth: the birth message is the first user message
        (progn
          (insert perm-birth-prompt)
          (message "[perm] BIRTH. Sending first message.")
          (gptel-send))
      ;; Concussion recovery: buffer restored from transcript below
      (message "[perm] RECOVERY at tick %d -- resuming life" perm--tick)))
  ;; Concussion recovery: restore buffer content from transcript
  (when (> perm--tick 0)
    (with-current-buffer perm--buf
      (erase-buffer)
      (insert-file-contents perm-transcript-path)
      (goto-char (point-max))
      (insert "\n\n" (perm--heartbeat) "\n\n")
      (gptel-send)))
  ;; Batch event loop: run forever
  (when noninteractive
    (while t
      (accept-process-output nil 5))))

(provide 'permanent-cycle)