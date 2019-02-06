;;;; Trac database extraction (for R7RS-WG1)

;;;; Copyright MMXVIII-MMXIX Arthur A. Gleckler.  All rights reserved.

;;; references:

;;; <https://trac.edgewall.org/wiki/TracDev/DatabaseSchema>
;;; <https://trac.edgewall.org/wiki/TracLinks>
;;; <https://trac.edgewall.org/wiki/WikiFormatting>
;;; <https://trac.edgewall.org/wiki/WikiHtml>

(declare (usual-integrations))

(define trac-attachments-pathname (->namestring "~/trac/trac-attachments"))
(define trac-database-pathname (->namestring "~/trac/trac2.db"))

(define (time-column name)
  (cons name
	(format #f "datetime(~A/1000000, 'unixepoch', 'utc')" name)))

(define trac-attachments
  (sqlite-extract
   trac-database-pathname
   "attachment"
   `("type"
     "id"
     "filename"
     "size"
     ,(time-column "time")
     "description"
     "author"
     "ipnr")))

(define trac-enums
  (sqlite-extract trac-database-pathname "enum" `("type" "name" "value")))

(define trac-milestones
  (sqlite-extract
   trac-database-pathname
   "milestone"
   `("name"
     ,(time-column "due")
     ,(time-column "completed")
     "description")))

(define trac-tickets
  (sqlite-extract
   trac-database-pathname
   "ticket"
   `("id"
     "type"
     ,(time-column "time")
     ,(time-column "changetime")
     "component"
     "severity"
     "priority"
     "owner"
     "reporter"
     "cc"
     "milestone"
     "status"
     "resolution"
     "summary"
     "description"
     "keywords")))

(define trac-ticket-changes
  (sqlite-extract
   trac-database-pathname
   "ticket_change"
   `("ticket"
     ,(time-column "time")
     ("raw-time" . "time")
     "author"
     "field"
     "oldvalue"
     "newvalue")))

(define trac-wiki
  (sqlite-extract
   trac-database-pathname
   "wiki"
   `("name"
     "version"
     ,(time-column "time")
     "author"
     "ipnr"
     "text"
     "comment"
     "readonly")))

(define (trac-get name object)
  (let ((result (cdr (assoc name object))))
    (if (json-null? result)
	""
	result)))

(define trac-css-path (make-parameter "/trac.css"))

(define-html-template (write-trac-page-core contents header title)
    ((head
      (write-standard-html-head "2013" (css (trac-css-path)) title)))
  ((html)
   head
   ((body)
    header
    ((ul class "navigation")
     ((li) ((a href "/") "Home"))
     ((li) ((a href "/ticket/") "All tickets"))
     ((li) ((a href "/wiki/") "All wiki pages")))
    contents)))

(define trac-bitbucket-missing-pages
  '("CamelCase" "CombinationsCowan" "EditingTracPagesInEmacs" "InterMapTxt"
    "InterTrac" "InterWiki" "PageTemplates" "RecentChanges" "SandBox"
    "SiteBackups" "SymbolsCowan" "TitleIndex" "TracAccessibility" "TracAdmin"
    "TracBackup" "TracBatchModify" "TracBrowser" "TracCgi" "TracChangeset"
    "TracEnvironment" "TracFastCgi" "TracFineGrainedPermissions" "TracGuide"
    "TracImport" "TracIni" "TracInstall" "TracInterfaceCustomization"
    "TracLinks" "TracLogging" "TracModPython" "TracModWSGI" "TracNavigation"
    "TracNotification" "TracPermissions" "TracPlugins" "TracQuery"
    "TracReports" "TracRepositoryAdmin" "TracRevisionLog" "TracRoadmap"
    "TracRss" "TracSearch" "TracStandalone" "TracSupport"
    "TracSyntaxColoring" "TracTickets" "TracTicketsCustomFields"
    "TracTimeline" "TracUnicode" "TracUpgrade" "TracWiki" "TracWikiElPatch"
    "TracWikiElWithPatch" "TracWorkflow" "WikiDeletePage" "WikiFormatting"
    "WikiHtml" "WikiMacros" "WikiNewPage" "WikiPageNames" "WikiProcessors"
    "WikiRestructuredText" "WikiRestructuredTextLinks" "WikiStart"))

(define trac-bitbucket-html-pages
  '("AdvancedRandomGauche"
    "CombinationsGauche"
    "IntegerSetsCowan"
    "JsoCowan"
    "PrimesGauche"))

(define-html-template (write-trac-header extension)
    ()
  ((header)
   "This site is a static rendering of the "
   ((a href "https://trac.edgewall.org/") "Trac")
   " instance that was used by "
   ((a href "http://scheme-reports.org/2015/working-group-1.html")
    "R7RS-WG1")
   " for its work on R7RS-small ("
   ((a href "/attachment/r7rs.pdf") "PDF")
   "), which was ratified in 2013.  For more information, see "
   ((a href "/") "Home")
   "."
   extension))

(define-html-template (write-trac-header-bitbucket-note-core name)
    ((url
      (format
       #f
       (if (member name trac-bitbucket-html-pages)
	   "https://htmlpreview.github.io/?https://bitbucket.org/cowan/r7rs-wg1-infra/raw/default/~A.html"
	   "https://bitbucket.org/cowan/r7rs-wg1-infra/src/default/~A.md")
       name)))
  "  For a version of this page that may be more recent, see "
  ((a href url) name)
  " in WG2's repo for R7RS-large.")

(define (write-trac-header-bitbucket-note name)
  (if (member name trac-bitbucket-missing-pages)
      ""
      (write-trac-header-bitbucket-note-core name)))

(define (write-trac-page contents title #!optional extension)
  (let ((extension (if (default-object? extension) "" extension)))
    (write-trac-page-core contents (write-trac-header extension) title)))

(define-html-template (write-trac-home-core)
    ((wikistart (write-trac-wiki (trac-latest-wiki "WikiStart"))))
  ((header)
   ((h1) "small.r7rs.org")
   ((p)
    "Welcome to "
    ((code) "small.r7rs.org")
    ".  This is the home of "
    ((a href "http://scheme-reports.org/2015/working-group-1.html") "R7RS Working Group 1")
    " (R7RS-WG1) and its work on the R7RS-small standard for the "
    ((a href "https://en.wikipedia.org/wiki/Scheme_(programming_language)")
     "Scheme programming language")
    ".  The R7RS-small standard ("
    ((a href "/attachment/r7rs.pdf") "PDF")
    ") was ratified in 2013.  The final standard as well as all working documents are now hosted here.")
   ((p)
    "(Originally, the standard and working documents were in a Trac instance, but that server was decommissioned in 2018.  The pages in this domain, except for this page, are static renderings of the wiki page and tickets from a complete backup of that Trac instance as of 14 Sep 2017.)")
   ((p) "An archive of the WG1 mailing list can be found "
    ((a href "https://groups.google.com/forum/#!forum/scheme-reports-wg1") "here")
    ".")
   ((p)
    ((a href "http://scheme-reports.org/2015/working-group-2.html") "WG2")
    "'s work on R7RS-large continues.  It is hosted at "
    ((a href "http://r7rs.org/") "r7rs.org")
    ", and includes most of the wiki pages used for R7RS-small, some of which have been modified since R7RS was ratified, as well as new ones, too.")
   ((p) "Below is the archived WG1 home page, "
    ((a href "/wiki/WikiStart") "WikiStart")
    "."))
  wikistart)

(define (write-trac-home)
  (write-trac-page-core (write-trac-home-core) "" "R7RS-small archive"))

(define-html-template (div-class k body) ()
  ((div class k) body))

(define (maybe-div name object)
  (let ((value (cdr (assoc name object))))
    (if (or (json-null? value)
	    (and (string? value) (string-null? value)))
	""
	(div-class name value))))

(define (trac-changes-for-ticket id)
  (filter (lambda (tc) (= id (trac-get "ticket" tc)))
	  trac-ticket-changes))

(define (trac-group-ticket-changes changes)
  (let ((sorted (sort changes
		      (lambda (c1 c2)
			(let ((t1 (trac-get "raw-time" c1))
			      (t2 (trac-get "raw-time" c2)))
			  (< t1 t2))))))
    (group-sorted-by-key
     (lambda (c1 c2)
       (let ((t1 (trac-get "raw-time" c1))
	     (t2 (trac-get "raw-time" c2)))
	 (= t1 t2)))
     sorted)))

(define (trac-maybe-empty string)
  (if (string-null? string)
      (make-raw-xml "&blank;")
      string))

(define-html-template (write-trac-ticket-single-change change)
    ((field (trac-get "field" change))
     (old-value (trac-maybe-empty (trac-get "oldvalue" change)))
     (new-value (trac-maybe-empty (trac-get "newvalue" change))))
  ((div)
   ((span class "field") field)
   ((span class "old-value") old-value)
   ((span class "new-value") new-value)))

(define-html-template (write-trac-ticket-comment change)
    ((new-value (wiki-process-string (trac-get "newvalue" change))))
  ((div class "comment") new-value))

(define-html-template (write-trac-ticket-group-changes changes)
    ((comments (compose-writer-makers
		write-trac-ticket-comment
		(filter (lambda (c) (string=? "comment" (trac-get "field" c)))
			changes)))
     (non-comments
      (compose-writer-makers
       write-trac-ticket-single-change
       (filter (lambda (c) (not (string=? "comment" (trac-get "field" c))))
	       changes))))
  ((div class "changes") non-comments)
  ((div class "comments") comments))

(define-html-template (write-trac-ticket-change-group group)
    ((ticket (trac-get "ticket" (car group)))
     (time (trac-get "time" (car group)))
     (author (trac-get "author" (car group)))
     (changes (write-trac-ticket-group-changes group)))
  ((div class "ticket change-group")
   ((div class "metadata")
    ((div class "author") author)
    ((div class "time") time))
   changes))

(define-html-template (write-trac-ticket ticket)
    ((id (trac-get "id" ticket))
     (description (wiki-process-string (trac-get "description" ticket)))
     (summary (trac-get "summary" ticket))
     (cc (maybe-div "cc" ticket))
     (changetime (maybe-div "changetime" ticket))
     (component (maybe-div "component" ticket))
     (keywords (maybe-div "keywords" ticket))
     (milestone (maybe-div "milestone" ticket))
     (owner (maybe-div "owner" ticket))
     (priority (maybe-div "priority" ticket))
     (reporter (maybe-div "reporter" ticket))
     (resolution (maybe-div "resolution" ticket))
     (severity (maybe-div "severity" ticket))
     (status (maybe-div "status" ticket))
     (time (maybe-div "time" ticket))
     (type (maybe-div "type" ticket))
     (changes (trac-changes-for-ticket id))
     (history
      (compose-writer-makers write-trac-ticket-change-group
			     (trac-group-ticket-changes changes)))
     (source (format #f "/ticket/~A/source.html" id)))
  ((h1 class "ticket")
   "Ticket "
   id
   ": "
   ((span class "summary") summary))
  ((div class "ticket metadata")
   cc
   changetime
   component
   keywords
   milestone
   owner
   priority
   reporter
   resolution
   severity
   ((div class "source")
    ((a href source) "source"))
   status
   time
   type)
  ((div class "ticket")
   ((div class "description") description)
   ((div class "history") history)))

(define (write-trac-ticket-page ticket)
  (write-trac-page
   (write-trac-ticket ticket)
   (format #f
	   "~A: ~A"
	   (trac-get "id" ticket)
	   (trac-get "summary" ticket))))

(define (trac-id ticket) (trac-get "id" ticket))

(define-html-template (write-trac-ticket-row ticket)
    ((id (trac-id ticket))
     (name (format #f "#~A" id))
     (summary (trac-get "summary" ticket))
     (component (trac-get "component" ticket))
     (milestone (trac-get "milestone" ticket))
     (type (trac-get "type" ticket))
     (severity (trac-get "severity" ticket))
     (owner (trac-get "owner" ticket))
     (status (trac-get "status" ticket))
     (time (trac-get "time" ticket))
     (link (format #f "/ticket/~A" id)))
  ((tr)
   (((td) ((a href link) name))
    ((td) summary)
    ((td) component)
    ((td) milestone)
    ((td) type)
    ((td) severity)
    ((td) owner)
    ((td) status)
    ((td) time))))

(define-html-template (write-trac-ticket-index)
    ((rows (compose-writer-makers
	    write-trac-ticket-row
	    (sort trac-tickets
		  (lambda (t1 t2) (> (trac-id t1) (trac-id t2)))))))
  ((h1) "All tickets")
  ((table class "tickets")
   ((tr)
    ((th) "Ticket")
    ((th) "Summary")
    ((th) "Component")
    ((th) "Milestone")
    ((th) "Type")
    ((th) "Severity")
    ((th) "Owner")
    ((th) "Status")
    ((th) "Created"))
   rows))

(define (write-trac-ticket-index-page)
  (write-trac-page
   (write-trac-ticket-index)
   "All Tickets"))

(define-html-template (write-single-attachment attachment)
    ((filename (trac-get "filename" attachment))
     (time (trac-get "time" attachment))
     (description (trac-get "description" attachment))
     (link (format #f "/attachment/~A" filename)))
  ((tr)
   ((td) ((a href link) filename))
   ((td) time)
   ((td) description)))

(define (sort-attachments attachments)
  (sort attachments
	(lambda (a1 a2)
	  (string<? (trac-get "filename" a1)
		    (trac-get "filename" a2)))))

(define-html-template (write-attachment-table attachments)
    ((rows (compose-writer-makers
	    write-single-attachment
	    (sort-attachments attachments))))
  ((h2) "Attachments")
  ((table class "attachments")
   ((tr)
    ((th) "filename")
    ((th) "time")
    ((th) "description"))
   rows))

(define (write-trac-attachments wiki)
  (let* ((name (trac-get "name" wiki))
	 (attachments (filter (lambda (a)
				(and (string=? name (trac-get "id" a))
				     (string=? "wiki" (trac-get "type" a))))
			      trac-attachments)))
    (if (null? attachments)
	'()
	(write-attachment-table attachments))))

(define-html-template (write-trac-wiki wiki)
    ((name (trac-get "name" wiki))
     (hyphenated (hyphenate-wiki-name name))
     (version (trac-get "version" wiki))
     (time (trac-get "time" wiki))
     (author (trac-get "author" wiki))
     (text (wiki-process-string (trac-get "text" wiki)))
     (comment (trac-get "comment" wiki))
     (history (format #f "/wiki/~A/history" name))
     (source (format #f "/wiki/~A/~A/source.html" name version))
     (attachments (write-trac-attachments wiki)))
  ((h1 class "wiki") hyphenated)
  ((div class "wiki metadata")
   ((div class "author") author)
   ((div class "time") time)
   ((div class "version")
    version
    ((span class "comment") comment)
    ((a href history) "history"))
   ((div class "source")
    ((a href source) "source")))
  ((div class "wiki text") text)
  attachments)

(define (write-trac-wiki-page wiki)
  (let ((name (trac-get "name" wiki)))
    (write-trac-page
     (write-trac-wiki wiki)
     name
     (write-trac-header-bitbucket-note name))))

(define (trac-version w) (trac-get "version" w))

(define (trac-latest-wiki name)
  (let ((candidates
	 (filter (lambda (w) (string=? name (trac-get "name" w)))
		 trac-wiki)))
    (extremum candidates
	      (lambda (w1 w2) (> (trac-version w1) (trac-version w2)))
	      (car candidates))))

(define-html-template (write-wiki-history-row wiki)
    ((author (trac-get "author" wiki))
     (comment (trac-get "comment" wiki))
     (name (trac-get "name" wiki))
     (time (trac-get "time" wiki))
     (version (trac-get "version" wiki))
     (link (format #f "/wiki/~A/~A" name version)))
  ((tr)
   ((td) ((a href link) version))
   ((td) time)
   ((td) author)
   ((td) comment)))

(define-html-template (write-trac-wiki-history name)
    ((versions
      (compose-writer-makers
       write-wiki-history-row
       (sort (filter (lambda (w) (string=? name (trac-get "name" w)))
		     trac-wiki)
	     (lambda (w1 w2) (> (trac-version w1) (trac-version w2)))))))
  ((h1) "Change History for " name)
  ((table class "history")
   ((tr)
    ((th) "Version")
    ((th) "Time")
    ((th) "Author")
    ((th) "Comment"))
   versions))

(define (write-trac-wiki-history-page name)
  (write-trac-page
   (write-trac-wiki-history name)
   (format #f "ChangeHistory for ~A" name)))

(define all-wiki-names
  (uniquify-strings (map (lambda (w) (trac-get "name" w)) trac-wiki)))

(define included-wiki-names
  (let ((special-case-omissions
	 '("CamelCase" "PageTemplates" "RecentChanges" "SandBox" "TitleIndex")))
    (filter (lambda (name)
	      (not (or (member name special-case-omissions)
		       (string-starts-with? "Inter" name)
		       (string-starts-with? "Trac" name)
		       (and (not (string=? name "WikiStart"))
			    (string-starts-with? "Wiki" name)))))
	    all-wiki-names)))

(define hyphenate-wiki-name
  (let ((change
	 (rexp-compile
	  (rexp-sequence char-set:lower-case char-set:upper-case))))
  (lambda (name)
    (let ((size (string-length name)))
      (let next ((accumulator '())
		 (i 0))
	(let ((transition (re-substring-search-forward change name i size)))
	  (if transition
	      (let* ((j (re-match-start-index 0 transition))
		     (next-lower
		      (or (substring-find-next-char-in-set
			   name
			   (1+ j)
			   size
			   char-set:lower-case)
			  size)))
		(next (cons*
		       (substring name (1+ j) next-lower)
		       (make-raw-xml "&shy;")
		       (substring name i (1+ j))
		       accumulator)
		      next-lower))
	      (reverse! (cons (substring name i size)
			      accumulator)))))))))

(define-html-template (write-trac-single-wiki name)
    ((hyphenated (hyphenate-wiki-name name))
     (link (format #f "/wiki/~A" name)))
  ((li)
   ((a href link) hyphenated)))

(define-html-template (write-trac-wiki-index)
    ((pages (compose-writer-makers write-trac-single-wiki
				   (sort included-wiki-names string<?))))
  ((h1) "All wiki pages")
  ((ul class "pages") pages))

(define (write-trac-wiki-index-page)
  (write-trac-page
   (write-trac-wiki-index)
   "All wiki pages"))

(define-html-template (write-component name value)
    ((string (if (json-null? value) "" value)))
  ((h2) name)
  ((pre) string))

(define-html-template (write-trac-source hn name object)
    ((components
      (compose-writer-makers
       (lambda (c) (write-component (car c) (cdr c)))
       (sort object (lambda (c1 c2) (string<? (car c1) (car c2))))))
     (heading (hn name)))
  heading
  components)

(define (write-trac-ticket-source name ticket)
  (let ((changes
	 (compose-writer-makers
	  (lambda (change)
	    (let ((name (format #f
				"Change at time ~A"
				(trac-get "time" change))))
	      (write-trac-source h2 name change)))
	  (trac-changes-for-ticket (trac-get "id" ticket)))))
    (write-trac-page
     (compose-writers
      (write-trac-source h1 name ticket)
      (h1 "Changes")
      changes)
     name)))

(define (write-trac-wiki-source name wiki)
  (write-trac-page
   (write-trac-source h1 name wiki)
   name))

(define-syntax write-wiki-file
  (syntax-rules ()
    ((_ (pattern arguments ...) writer)
     (with-output-to-file (format #f pattern arguments ...)
       (lambda () (invoke-writer writer))))))

(define (write-trac directory)
  (define (ensure-directory-exists pattern . arguments)
    (let ((pathname (apply format #f pattern arguments)))
      (cond ((file-directory? pathname))
	    ((file-exists? pathname)
	     (error "Must be a directory." pathname))
	    (else (make-directory pathname)))))
  (assert (file-directory? directory))
  (with-working-directory-pathname (pathname-as-directory directory)
    (lambda ()
      (ensure-directory-exists "attachment/")
      (do-list (a trac-attachments)
	(let ((filename (trac-get "filename" a)))
	  (copy-file (extend-pathname filename trac-attachments-pathname)
		     (extend-pathname filename "attachment/"))))
      (ensure-directory-exists "ticket/")
      (write-wiki-file ("ticket/index.html")
	  (write-trac-ticket-index-page))
      (do-list (t trac-tickets)
	(let ((id (trac-id t)))
	  (ensure-directory-exists "ticket/~A/" id)
	  (write-wiki-file ("ticket/~A/index.html" id)
	      (write-trac-ticket-page t))
	  (write-wiki-file ("ticket/~A/source.html" id)
	      (write-trac-ticket-source (format #f "Source for ticket #~A" id)
					t))))
      (ensure-directory-exists "wiki/")
      (write-wiki-file ("index.html")
	  (write-trac-home))
      (write-wiki-file ("wiki/index.html")
	  (write-trac-wiki-index-page))
      (let ((wiki-names included-wiki-names))
	(do-list (wn wiki-names)
	  (ensure-directory-exists "wiki/~A/" wn)
	  (ensure-directory-exists "wiki/~A/history/" wn)
	  (let ((wiki (trac-latest-wiki wn)))
	    (write-wiki-file ("wiki/~A/index.html" wn)
		(write-trac-wiki-page wiki)))
	  (write-wiki-file ("wiki/~A/history/index.html" wn)
	      (write-trac-wiki-history-page wn))
	  (let ((versions (filter (lambda (w) (string=? wn (trac-get "name" w)))
				  trac-wiki)))
	    (do-list (wiki versions)
	      (let ((version (trac-get "version" wiki)))
		(ensure-directory-exists "wiki/~A/~A/" wn version)
		(write-wiki-file ("wiki/~A/~A/index.html" wn version)
		    (write-trac-wiki-page wiki))
		(write-wiki-file ("wiki/~A/~A/source.html" wn version)
		    (write-trac-wiki-source
		     (format #f "Source for wiki ~A version ~A" wn version)
		     wiki))))))))))

(define (write-trac-input)
  "Write all Trac input to a file.  This is useful for seeing what
WikiFormatting is actually used."
  (with-output-to-file "/tmp/trac-input.scm"
    (lambda ()
      (for-each pp trac-tickets)
      (do-list (wn all-wiki-names)
	(pp (trac-latest-wiki wn))))))

(define (string->lines string)
  (with-input-from-string string
    (lambda ()
      (let next-line ((accumulator '()))
	(let ((line (read-line)))
	  (if (eof-object? line)
	      (reverse! accumulator)
	      (next-line (cons line accumulator))))))))

(define wiki-transforms '())

(define-record-type wiki-transform
    (make-wiki-transform name search guard transform)
    transform?
  (guard wt/guard)
  (name wt/name)
  (search wt/search)
  (transform wt/transform))

(define-record-type wiki-transform-result
    (make-wiki-transform-result data start end)
    transform-result?
  (data wtr/data)
  (end wtr/end)
  (start wtr/start))

(define (remove-transform! name)
  (set! wiki-transforms
	(remove (lambda (wt) (eq? name (wt/name wt)))
		wiki-transforms))
  name)

(define (add-transform! name search transform #!optional guard)
  (set! wiki-transforms
	(cons (make-wiki-transform name
				   search
				   (and (not (default-object? guard))
					guard)
				   transform)
	      (remove (lambda (wt) (eq? name (wt/name wt)))
		      wiki-transforms)))
  name)

(define (add-rexp-transform! name rexp transform #!optional guard)
  (add-transform! name
      (let ((regexp (rexp-compile rexp)))
	(lambda (string start)
	  (let ((registers
		 (re-substring-search-forward regexp
					      string
					      start
					      (string-length string))))
	    (and registers
		 (make-wiki-transform-result
		  registers
		  (re-match-start-index 0 registers)
		  (re-match-end-index 0 registers))))))
    (lambda (result string)
      (transform (wtr/data result) string))
    guard))

(add-rexp-transform! 'bare-wiki-name
    (rexp-sequence (rexp-word-start)
		   (apply rexp-alternatives all-wiki-names)
		   (rexp-word-end))
  (lambda (registers string)
    (let ((name (re-match-extract string registers 0)))
      (href-simple name (format #f "/wiki/~A" name)))))

(define (char-lower-case? character)
  (char-set-member? char-set:lower-case character))

(define (char-upper-case? character)
  (char-set-member? char-set:upper-case character))

(define camel-case
  (rexp+ (rexp-sequence char-set:upper-case
			(rexp+ char-set:lower-case))))

(define camel-case?
  (let ((camel (rexp-compile (rexp-sequence (rexp-string-start)
					    camel-case
					    (rexp-string-end)))))
    (lambda (string)
      (not (not (re-string-match camel string))))))

(define-test-group (wiki camel-case?)
  (lambda (string expected)
    (assert (eq? expected (camel-case? string))))
  '("A" #f)
  '("a" #f)
  '("AB" #f)
  '("Ab" #t)
  '("AbC" #f)
  '("AbCd" #t)
  '("AbCD" #f))

(add-rexp-transform! 'bare-wiki-name-not
    (rexp-sequence "!" camel-case)
  (lambda (registers string)
    (string-tail (re-match-extract string registers 0) 1)))

(define-test-group (wiki bare-wiki-name-not)
  (lambda (string expected)
    (check-wiki-transform wiki-transform expected string))
  '("!WikiStart" "WikiStart")
  '("!FooBar" "FooBar"))

(define wiki-link-mapping
  '(("http://trac.sacrideo.us/wg/attachment/wiki/WikiStart/r7rs.pdf"
     "/attachment/r7rs.pdf")
    ("http://trac.sacrideo.us/wg/attachment/wiki/WikiStart/scheme-wg1-progress1.pdf"
     "/attachment/scheme-wg1-progress1.pdf")
    ("http://trac.sacrideo.us/wg/raw-attachment/wiki/WikiStart/r7rs-draft-8.pdf"
     "/attachment/r7rs-draft-8.pdf")
    ("http://trac.sacrideo.us/wg/raw-attachment/wiki/WikiStart/r7rs-small-spec.zip"
     "/attachment/r7rs-small-spec.zip")
    ("http://trac.sacrideo.us/wg/raw-attachment/wiki/WikiStart/r7rs.pdf"
     "/attachment/r7rs.pdf")
    ("http://trac.sacrideo.us/wg/wiki/BlobAPI"
     "/wiki/BlobAPI")
    ("http://trac.sacrideo.us/wg/wiki/ContainerSrfiComparison#Maximalistproposal"
     "/wiki/ContainerSrfiComparison#Maximalistproposal")
    ("http://trac.sacrideo.us/wg/wiki/WG1Ballot6Results#a433fullconversioncycleforcontainers"
     "/wiki/WG1Ballot6Results#a433fullconversioncycleforcontainers")))

(add-rexp-transform! 'bracketed-link
    (rexp-sequence "["
		   (rexp-group
		    (rexp-alternatives "ftp://" "http://" "https://")
		    (rexp+ (char-set-invert
			    (char-set-union char-set:whitespace
					    (char-set #\])))))
		   (rexp-alternatives
		    (rexp-sequence
		     (rexp-alternatives " " "\t")
		     (rexp+ (char-set-invert (char-set #\]))))
		    "")
		   "]")
  (lambda (registers string)
    (let* ((text (string-trim (re-match-extract string registers 3)))
	   (raw-url (re-match-extract string registers 1))
	   (url (cond ((assoc raw-url wiki-link-mapping) => cadr)
		      (else raw-url))))
      (href-simple (if (string-null? text) url text)
		   url))))

(add-rexp-transform! 'bracketed-wiki-name
    (rexp-sequence "["
		   (rexp-group (apply rexp-alternatives all-wiki-names))
		   (rexp-alternatives
		    (rexp-sequence
		     (rexp-alternatives " " "\t")
		     (rexp+ (char-set-invert (char-set #\]))))
		    "")
		   "]")
  (lambda (registers string)
    (let* ((text (string-trim (re-match-extract string registers 2)))
	   (name (re-match-extract string registers 1))
	   (url (format #f "/wiki/~A" name)))
      (href-simple (if (string-null? text) name text)
		   url))))

(add-rexp-transform! 'bracketed-wiki-link
    (rexp-sequence "[wiki:"
		   (rexp-group
		    (rexp+ (char-set-invert
			    (char-set-union char-set:whitespace
					    (char-set #\])))))
		   (rexp-alternatives
		    (rexp-sequence
		     (rexp-alternatives " " "\t")
		     (rexp+ (char-set-invert (char-set #\]))))
		    "")
		   "]")
  (lambda (registers string)
    (let* ((text (string-trim (re-match-extract string registers 2)))
	   (name (re-match-extract string registers 1))
	   (url (format #f "/wiki/~A" name)))
      (href-simple (if (string-null? text) name text)
		   url))))

(define (read-matching-lines rexp #!optional guard)
  (let ((guard (if (default-object? guard)
		   (lambda (string start end) #t)
		   guard))
	(regexp (rexp-compile rexp)))
    (lambda (string start end)
      (let next ((accumulator '())
		 (index start))
	(let ((registers (re-substring-search-forward regexp string index end)))
	  (if (and registers
		   (guard string (re-match-start-index 0 registers) end))
	      (next (cons registers accumulator)
		    (re-match-end-index 0 registers))
	      (values (reverse! accumulator)
		      index)))))))

(define citation-line
  (rexp-sequence
   (rexp-line-start)
   (rexp-group (rexp+ ">"))
   (rexp-group (rexp+ (char-set-invert (char-set #\return #\newline))))))

(define read-citation-lines (read-matching-lines citation-line))

(define-html-template (write-citation body) ()
  ((blockquote class "citation") body))

(define (transform-citation string start end)
  (define (what-level registers)
    (- (re-match-end-index 1 registers)
       (re-match-start-index 1 registers)))
  (define (extract registers)
    (re-match-extract string registers 2))
  (define (transform-prefix accumulator)
    (let-values (((strings rest)
		  (split-list accumulator (lambda (x) (not (string? x))))))
      (cons (wiki-process-string (string-join "\n" (reverse! strings)))
	    rest)))
  (define (read-level accumulator level remaining)
    (if (null? remaining)
	(values (write-citation (reverse! (transform-prefix accumulator))) '())
	(let ((new-level (what-level (car remaining))))
	  (cond ((= new-level level)
		 (read-level (cons (extract (car remaining)) accumulator)
			     level
			     (cdr remaining)))
		((> new-level level)
		 (let-values (((result left)
			       (read-level '() (1+ level) remaining)))
		   (read-level (cons result (transform-prefix accumulator))
			       level
			       left)))
		(else (values (write-citation
			       (reverse! (transform-prefix accumulator)))
			      remaining))))))
  (let*-values (((registers-list citation-end)
		 (read-citation-lines string start end))
		((result left) (read-level '() 1 registers-list)))
    (values result citation-end)))

(define-html-template (wiki-h1 sid text) ()
  ((h1 id sid) text))

(define-html-template (wiki-h2 sid text) ()
  ((h2 id sid) text))

(define-html-template (wiki-h3 sid text) ()
  ((h3 id sid) text))

(define-html-template (wiki-h4 sid text) ()
  ((h4 id sid) text))

(define-html-template (wiki-h5 sid text) ()
  ((h5 id sid) text))

(define-html-template (wiki-h6 sid text) ()
  ((h6 id sid) text))

(define whitespace-regexp
  (rexp-compile char-set:whitespace))

(define (remove-whitespace string)
  (let ((size (string-length string)))
    (let next ((accumulator '())
	       (i 0))
      (let ((registers (re-substring-search-forward whitespace-regexp
						    string
						    i
						    size)))
	(if registers
	    (next (cons (substring string i
				   (re-match-start-index 0 registers))
			accumulator)
		  (re-match-end-index 0 registers))
	    (apply string-append
		   (reverse! (cons (string-tail string i)
				   accumulator))))))))

(define (wiki-heading->name text)
  (remove-whitespace
   (with-output-to-string
     (lambda ()
       (let descend ((text text))
	 (cond ((string? text) (write-string text))
	       ((writer? text))
	       ((list? text) (for-each descend text))
	       (else (error "Unexpected type in text." text))))))))

(define (wiki-headline level sid text)
  (let ((body (wiki-transform (string-trim text))))
    (case level
      ((1) (wiki-h1 sid body))
      ((2) (wiki-h2 sid body))
      ((3) (wiki-h3 sid body))
      ((4) (wiki-h4 sid body))
      ((5) (wiki-h5 sid body))
      (else (wiki-h6 sid body)))))

(define headline-line
  (rexp-sequence (rexp-line-start)
		 (rexp-group
		  (rexp-alternatives "=" "==" "===" "====" "=====" "======"))
		 " "
		 (rexp-group
		  (rexp+ (char-set-invert (char-set #\newline #\return))))))

(define transform-headline
  (let ((headline-regexp (rexp-compile headline-line))
	(anchor-regexp
	 (rexp-compile
	  (rexp-sequence "#"
			 (rexp-group (rexp+ char-set:not-whitespace))
			 (rexp-line-end)))))
    (lambda (string start end)
      (let ((registers (re-substring-match headline-regexp string start end)))
	(let* ((marker (re-match-extract string registers 1))
	       (level (string-length marker))
	       (rest (re-match-extract string registers 2))
	       (anchor (re-string-search-backward anchor-regexp rest))
	       (text (if anchor
			 (string-head rest (re-match-start-index 0 anchor))
			 rest))
	       (before-whitespace (string-trim-right text))
	       (body (if (= level
			    (string-match-backward marker before-whitespace))
			 (string-head text
				      (- (string-length before-whitespace)
					 level))
			 text))
	       (id (if anchor
		       (re-match-extract rest anchor 1)
		       (wiki-heading->name body))))
	  (values (wiki-headline level id body)
		  (re-match-end-index 0 registers)))))))

(define-test-group (wiki headline)
  (lambda (input expected)
    (check-wiki-transform
     (lambda (string)
       (let-values (((result end)
		     (transform-headline string 0 (string-length string))))
	 result))
     expected
     input))
  '("=== #460 Semantics of `eqv?` ==="
    "\n<h3 id=\"#460Semanticsof`eqv?`\"><a href=\"/ticket/460\">#460</a> Semantics of <span class=\"monospace\">eqv?</span></h3>")
  '("=== #460 Semantics of `eqv?` ===\r\n"
    "\n<h3 id=\"#460Semanticsof`eqv?`\"><a href=\"/ticket/460\">#460</a> Semantics of <span class=\"monospace\">eqv?</span></h3>")
  '("=== `[mainnav]` #mainnav-bar"
    "\n<h3 id=\"mainnav-bar\"><span class=\"monospace\">[mainnav]</span></h3>"))

(define item-alphabetic (rexp-sequence (rexp-group char-set:alphabetic) "."))
(define item-bullet (rexp-alternatives "* " "- "))
(define item-numeric (rexp-sequence (rexp-group (rexp+ char-set:numeric)) "."))
(define item-roman
  (rexp-sequence
   (rexp-group (rexp+ (rexp-case-fold (string->char-set "mclxvi"))))
   "."))

(define item-prefix
  (rexp-alternatives item-alphabetic
		     item-bullet
		     item-numeric
		     item-roman))

(define item-content
  (rexp-sequence item-prefix
		 (rexp* (rexp-any-char))
		 (rexp-line-end)))

(define outline-line
  (rexp-sequence (rexp-line-start)
		 (rexp* (rexp-alternatives " " "\t"))
		 item-content))

(define blockquote-line
  (rexp-sequence
   "  "
   (rexp-group (rexp+ (char-set-invert (char-set #\return #\newline))))))

(define read-blockquote-lines
  (let ((outline (rexp-compile outline-line)))
    (read-matching-lines
     blockquote-line
     (lambda (string start end)
       (not (re-substring-match outline string start end))))))

(define-html-template (write-blockquote body) ()
  ((blockquote) body))

(define (transform-blockquote string start end)
  (let-values (((registers-list blockquote-end)
		(read-blockquote-lines string start end)))
    (values (write-blockquote
	     (wiki-process-string
	      (string-join "\n"
			   (map (lambda (r) (re-match-extract string r 1))
				registers-list))))
	    blockquote-end)))

(define line-break (rexp-sequence (rexp-optional "\r") "\n"))
(define paragraph-break (rexp-sequence line-break (rexp+ line-break)))

;; This doesn't handle tabs.  I'm not sure whether WikiFormatting is
;; supposed to do that.
(define read-outline
  (let ((break (rexp-compile paragraph-break))
	(continuation-line (rexp-compile
			    (rexp-sequence (rexp+ (rexp-any-char))
					   (rexp-line-end))))
	(item-content (rexp-compile item-content))
	(leading-whitespace
	 (rexp-compile
	  (rexp-sequence (rexp-line-start)
			 (rexp+ (rexp-alternatives " " "\t"))))))
    (lambda (string start end)
      (define (measure-whitespace offset)
	(let ((reg (re-substring-match leading-whitespace string offset end)))
	  (if reg
	      (- (re-match-end-index 0 reg) offset)
	      0)))
      (define (read-level accumulator indentation offset)
	(if (>= offset end)
	    (values (reverse! accumulator) end)
	    (let* ((new-indentation (measure-whitespace offset))
		   (content (+ offset new-indentation)))
	      (cond ((re-substring-match item-content string content end)
		     => (lambda (reg)
			  (cond ((= new-indentation indentation)
				 (let ((line-end (re-match-end-index 0 reg)))
				   (read-level
				    (cons (list (cons content line-end))
					  accumulator)
				    indentation
				    (1+ line-end))))
				((> new-indentation indentation)
				 (let-values (((sublist new-offset)
					       (read-level '()
							   new-indentation
							   offset)))
				   (read-level (cons (cons (caar accumulator)
							   sublist)
						     (cdr accumulator))
					       indentation
					       new-offset)))
				(else (values (reverse! accumulator) offset)))))
		    ((re-substring-match continuation-line string content end)
		     => (lambda (reg)
			  (if (or (zero? new-indentation)
				  (< new-indentation indentation))
			      (values (reverse! accumulator) offset)
			      (let* ((line-end (re-match-end-index 0 reg))
				     (continuation
				      (substring string content line-end)))
				(read-level
				 (cons (list (cons (caaar accumulator)
						   line-end))
				       (cdr accumulator))
				 indentation
				 (1+ line-end))))))
		    (else (values (reverse! accumulator) offset))))))
      (read-level (list (cons 0 0)) (measure-whitespace start) start))))

;; Return the item type and, if the value is not the initial value for
;; a list, that value.
(define item-type
  (let ((alphabetic (rexp-compile item-alphabetic))
	(bullet (rexp-compile item-bullet))
	(numeric (rexp-compile item-numeric))
	(roman (rexp-compile item-roman)))
    (define (char-lower-case? character)
      (char-set-member? char-set:lower-case character))
    (define (initial-lower? value) (char-lower-case? (string-ref value 0)))
    (lambda (string)
      (define ((choose-match initial-lower initial-upper lower-type upper-type)
	       registers)
	(let ((value (re-match-extract string registers 1)))
	  (cond ((string=? value initial-lower) (values lower-type #f))
		((string=? value initial-upper) (values upper-type #f))
		((initial-lower? value) (values lower-type value))
		(else (values upper-type value)))))
      (cond ((re-string-match roman string)
	     => (choose-match "i" "I" 'roman-lower 'roman-upper))
	    ((re-string-match alphabetic string)
	     => (choose-match "a" "A" 'alpha-lower 'alpha-upper))
	    ((re-string-match bullet string) (values 'bullet #f))
	    ((re-string-match numeric string)
	     => (lambda (registers)
		  (let ((number (re-match-extract string registers 1)))
		    (values 'number (and (not (string=? "1" number)) number)))))
	    (else (error "Unrecognized item type." string))))))

(define-test-group (wiki item-type)
  (lambda (input expected-type expected-value)
    (let-values (((type value) (item-type input)))
      (assert (eq? expected-type type))
      (assert (or (not (or expected-value value))
		  (string=? expected-value value)))))
  '("-" bullet #f)
  '("*" bullet #f)
  '("c." roman-lower "c")		; Conflicts with Roman.  We
					; choose Roman over letter in
					; this case.
  '("i." roman-lower #f)
  '("x." roman-lower "x")
  '("I." roman-upper #f)
  '("X." roman-upper "X")
  '("a." alpha-lower #f)
  '("A." alpha-upper #f)
  '("b." alpha-lower "b")
  '("B." alpha-upper "B")
  '("1." number #f)
  '("2." number "2"))

(define (outline-type string outline)
  (if (number? (car outline))
      (item-type (substring string (car outline) (cdr outline)))
      (outline-type string (car outline))))

(define-html-template (ol+class k ol-items) ()
  ((ol class k) ol-items))

(define-html-template (ol+class+start k v ol-items) ()
  ((ol class k start v) ol-items))

(define item-suffix
  (let ((prefix (rexp-compile item-prefix)))
    (lambda (string)
      (let ((registers (re-string-match prefix string)))
	(if registers
	    (string-trim
	     (string-tail string (re-match-end-index 0 registers)))
	    "")))))

(define (transform-outline string start end)
  (let-values (((sublist offset) (read-outline string start end)))
    (values
     (let descend ((outline sublist))
       (if (number? (car outline))
	   (wiki-transform
	    (item-suffix
	     (substring string (car outline) (cdr outline))))
	   (compose-writers
	    (descend (car outline))
	    (if (null? (cdr outline))
		'()
		(let*-values (((type value) (outline-type string (cdr outline)))
			      ((wrap)
			       (cond ((eq? type 'bullet) ul)
				     (value
				      (lambda (ol-items)
					(ol+class+start
					 (symbol->string type)
					 (case type
					   ((alpha-lower alpha-upper)
					    (- (char->integer
						(char-upcase
						 (string-ref value 0)))
					       64))
					   ((roman-lower roman-upper)
					    (roman->integer value))
					   ((number) value)
					   (else "Unrecognized item type."
						 type))
					 ol-items)))
				     (else (lambda (ol-items)
					     (ol+class (symbol->string type)
						       ol-items))))))
		  (wrap (compose-writer-makers
			 (lambda (item) (li (descend item)))
			 (cdr outline))))))))
     offset)))

(define processor-line
  (rexp-compile
   (rexp-sequence "#!"
		  (rexp-group
		   (rexp+ (char-set-invert (char-set #\newline #\return))))
		  line-break)))

;; <> Use `rexp's here, too.
(define open-re
  (re-compile-pattern "^[ \t]*{{{\\(#!\\|[ \t]*\r?\n\\([ \t]*#!\\)?\\)" #t))

;; <> Use `rexp's here, too.
(define close-re (re-compile-pattern "^[ \t]*}}}[ \t]*\\(\r?\n\\|$\\)" #t))

(define (read-curlies string start end)
  "Given substring [start, end) of `string', where `start' is
immediately before an opening {{{, return a nested description of its
line-based {{{ }}} pairs.  Each sublist starts with a possibly-empty
process name string that is followed by both pairs of offsets into the
string and lists that represent {{{ }}}-enclosed regions.  The pairs
represent un-enclosed regions."
  (let collect ((accumulator '())
		(i start)
		(level 0))
    (define (ascend start end)
      (values (reverse! (cons (cons i start) accumulator))
	      end))
    (let* ((open (re-substring-search-forward open-re string i end))
	   (close (re-substring-search-forward close-re string i end)))
      (cond (open
	     (let ((open-start (re-match-start-index 0 open)))
	       (if (and close
			(< (re-match-start-index 0 close)
			   open-start))
		   (ascend (re-match-start-index 0 close)
			   (re-match-end-index 0 close))
		   (let* ((open-end (re-match-end-index 0 open))
			  (processor
			   (re-substring-match processor-line
					       string
					       (- open-end 2)
					       end))
			  (continue (if processor
					(re-match-end-index 0 processor)
					open-end))
			  (processor-spec
			   (if processor
			       (re-match-extract string processor 1)
			       "")))
		     (let-values (((inner end)
				   (collect '() continue (1+ level))))
		       (if (zero? level)
			   (values (cons processor-spec inner)
				   end)
			   (collect (cons* (cons processor-spec inner)
					   (cons i open-start)
					   accumulator)
				    end
				    level)))))))
	    (close
	     (ascend (re-match-start-index 0 close)
		     (re-match-end-index 0 close)))
	    (else (ascend end end))))))

(define (transform-curlies-named string start end)
  (let-values (((curlies offset)
		(read-curlies string start end)))
    (define (descend c)
      (if (and (pair? c) (number? (car c)))
	  (wiki-process-regions string (car c) (cdr c))
	  (let ((processor-spec (car c))
		(rest (cdr c)))
	    (let-values (((name parameters)
			  (split-string-once processor-spec " ")))
	      (let ((transform
		     (cond ((find (lambda (wp) (string=? name (wp/name wp)))
				  wiki-processors)
			    => wp/transform)
			   (else preformatted-processor))))
		(transform descend parameters rest string))))))
    (let-values (((name parameters) (split-string-once (car curlies) " ")))
      (values (descend curlies)
	      offset
	      name))))

(define (transform-curlies string start end)
  (let-values (((writers curlies-end name)
		(transform-curlies-named string start end)))
    (cond ((or (string=? name "td")
	       (string=? name "th"))
	   (transform-table-cells string (list writers) '() curlies-end end))
	  ((string=? name "tr")
	   (transform-table-rows string (list writers) curlies-end end))
	  (else (values writers curlies-end)))))

(define table-line
  (rexp-sequence (rexp-line-start)
		 "||"
		 (rexp-group (rexp+ (char-set-invert
				     (char-set #\return #\newline))))
		 "||"
		 (rexp-group
		  (rexp-sequence
		   (rexp* (rexp-alternatives " " "\t"))
		   (rexp-group (rexp-optional "\\"))
		   (rexp* (rexp-alternatives " " "\t"))))
		 (rexp-alternatives line-break
				    (rexp-line-end))))

(define table-line-re (rexp-compile table-line))

(define (read-table-cells string start end)
  "Read the contents of all \"||\"-based table cells on the line
starting at `start', return them as a list.  Also return the offset of
the end of the line as well as whether a \"\\\\\" continuation mark
appeared."
  (let ((line (re-substring-match table-line-re string start end)))
    (if line
	(values (split-string
		 (re-match-extract string line 1)
		 "||")
		(re-match-end-index 0 line)
		(not (string-null? (re-match-extract string line 2))))
	(values '() start #f))))

(define (table-header-cell string)
  (let ((size (string-length string)))
    (and (>= size 2)
	 (char=? #\= (string-ref string 0))
	 (char=? #\= (string-ref string (-1+ size)))
	 (substring string 1 (-1+ size)))))

(define (table-spans cells)
  (let next ((count 1)
	     (spans '())
	     (remaining cells))
    (if (null? remaining)
	(reverse! spans)
	(let ((first (car remaining)))
	  (if (string-null? first)
	      (next (1+ count)
		    spans
		    (cdr remaining))
	      (next 1
		    (cons (cons count first) spans)
		    (cdr remaining)))))))

;; Centering is requested by using more than one space on either side,
;; not just one on either side or more than one on just one side.  The
;; WikiFormatting page doesn't make this clear, but the Trac code does
;; (<https://github.com/edgewall/trac/blob/trunk/trac/wiki/formatter.py>).
(define (cell-alignment string)
  (define (whitespace-count-max-2 limit start step)
    (cond ((= start limit) 0)
	  ((char-whitespace? (string-ref string start))
	   (let ((next (step start)))
	     (cond ((= next limit) 1)
		   ((char-whitespace? (string-ref string next)) 2)
		   (else 1))))
	  (else 0)))
  (let* ((size (string-length string))
	 (left (whitespace-count-max-2 size 0 1+))
	 (right (whitespace-count-max-2 -1 (-1+ size) -1+)))
    (cond ((and (= left 2) (= right 2)) 'center)
	  ((and (zero? left) (not (zero? right))) 'left)
	  ((and (not (zero? left)) (zero? right)) 'right)
	  (else 'default))))

(define-test-group (wiki cell-alignment)
  (lambda (expected input)
    (assert (eq? expected (cell-alignment input))))
  '(left    "left align    ")
  '(center  "  center      ")
  '(right   "      right align")
  '(default " default alignment ")
  '(default "default")
  '(default "  default ")
  '(default " default "))

;; <> If `define-html-template' had the ability to parameterize on the
;; tag and to omit attributes that were not supplied at runtime, these
;; could collapse into a single template.
(define-html-template (wiki-table-cell alignment contents) ()
  ((td class alignment) contents))

(define-html-template (wiki-table-header alignment contents) ()
  ((th class alignment) contents))

(define-html-template (wiki-table-cell-span alignment contents count) ()
  ((td class alignment colspan count) contents))

(define-html-template (wiki-table-header-span alignment contents count) ()
  ((th class alignment colspan count) contents))

(define (write-table-line cells)
  (compose-writer-makers
   (lambda (span)
     (let ((colspan (car span))
	   (body (cdr span)))
       (let* ((header? (table-header-cell body))
	      (contents (or header? body))
	      (alignment (cell-alignment contents))
	      (class (symbol->string alignment))
	      (writer (wiki-process-string contents)))
	 (if header?
	     (if (= colspan 1)
		 (wiki-table-header class writer)
		 (wiki-table-header-span class writer colspan))
	     (if (= colspan 1)
		 (wiki-table-cell class writer)
		 (wiki-table-cell-span class writer colspan))))))
   (table-spans cells)))

(define row-separator
  (rexp-compile
   (rexp-sequence (rexp-line-start)
		  "|"
		  (rexp+ "-")
		  (rexp-alternatives line-break
				     (rexp-line-end)))))

(define (transform-table-cells string cells rows start end)
  (let next-cell ((cells cells)
		  (offset start))
    (cond ((re-substring-match row-separator string offset end)
	   => (lambda (registers)
		(transform-table-rows string
				      (cons (tr (reverse cells)) rows)
				      (re-match-end-index 0 registers)
				      end)))
	  ((re-substring-match open-re string offset end)
	   (let-values (((writers curlies-end name)
			 (transform-curlies-named string offset end)))
	     (cond ((or (string=? name "td")
			(string=? name "th"))
		    (next-cell (cons (list writers) cells) curlies-end))
		   ((string=? name "tr")
		    (transform-table-rows string
					  (cons* (list writers)
						 (tr (reverse cells))
						 rows)
					  curlies-end
					  end))
		   (else
		    (values (table (cons* (reverse rows)
					  (tr (reverse cells))
					  writers))
			    curlies-end)))))
	  (else
	   (let-values (((new-cells table-end continues?)
			 (read-table-cells string offset end)))
	     (if continues?
		 (next-cell (cons (write-table-line new-cells)
				  cells)
			    table-end)
		 (transform-table-rows
		  string
		  (cons (tr (cons (reverse cells)
				  (write-table-line new-cells)))
			rows)
		  table-end
		  end)))))))

(define (transform-table-rows string rows offset end)
  (let-values (((cells table-end continues?)
		(read-table-cells string offset end)))
    (if (null? cells)
	(cond ((re-substring-match row-separator string table-end end)
	       => (lambda (registers)
		    (transform-table-rows string
					  rows
					  (re-match-end-index 0 registers)
					  end)))
	      ((re-substring-match open-re string table-end end)
	       (let-values (((writers curlies-end name)
			     (transform-curlies-named string table-end end)))
		 (cond ((or (string=? name "td")
			    (string=? name "th"))
			(transform-table-cells string
					       (list writers)
					       rows
					       curlies-end
					       end))
		       ((string=? name "tr")
			(transform-table-rows string
					      (cons (list writers) rows)
					      curlies-end
					      end))
		       (else
			(values (table (cons (reverse rows) writers))
				curlies-end)))))
	      (else (values (table (reverse rows)) table-end)))
	(if continues?
	    (transform-table-cells string
				   (write-table-line cells)
				   rows
				   table-end
				   end)
	    (transform-table-rows string
				  (cons (tr (write-table-line cells))
					rows)
				  table-end
				  end)))))

(define (transform-table string start end)
  (transform-table-rows string '() start end))

(define-test-group (wiki transform-table)
  (lambda (input expected)
    (let* ((string (string-join "\n" input))
	   (size (string-length string)))
      (let-values (((writer offset) (transform-table string 0 size)))
	(assert (= offset size))
	(assert (string=? (string-join "\n" expected)
			  (with-output-to-string
			    (lambda () (invoke-writer writer))))))))
  '(("||=foo =|| \\"
     "||= bar =||"
     "|| baz|| \\"
     "|| bat ||")
    (""
     "<table>"
     "  <tr>"
     "    <th class=\"left\">"
     "      <p>foo</p></th>"
     "    <th class=\"default\">"
     "      <p>bar</p></th></tr>"
     "  <tr>"
     "    <td class=\"right\">"
     "      <p>baz</p></td>"
     "    <td class=\"default\">"
     "      <p>bat</p></td></tr></table>"))
  '(("||= foo=|| \\"
     "||=bar =|| \\"
     "||= baz =|| \\"
     "||= bat=||"
     "{{{#!td"
     "alpha"
     "}}}"
     "{{{#!td"
     "bravo"
     "}}}"
     "|| charlie || delta ||"
     "|--------------------"
     "|| echo || \\"
     "{{{#!td"
     "foxtrot"
     "}}}"
     "{{{#!tr"
     "  {{{#!td"
     "golf"
     "  }}}"
     "  {{{#!td"
     "hotel"
     "  }}}"
     "}}}")
    (""
     "<table>"
     "  <tr>"
     "    <th class=\"right\">"
     "      <p>foo</p></th>"
     "    <th class=\"left\">"
     "      <p>bar</p></th>"
     "    <th class=\"default\">"
     "      <p>baz</p></th>"
     "    <th class=\"right\">"
     "      <p>bat</p></th></tr>"
     "  <tr><td >"
     "    <p>alpha</p></td><td >"
     "    <p>bravo</p></td>"
     "    <td class=\"default\">"
     "      <p>charlie</p></td>"
     "    <td class=\"default\">"
     "      <p>delta</p></td></tr>"
     "  <tr>"
     "    <td class=\"default\">"
     "      <p>echo</p></td><td >"
     "    <p>foxtrot</p></td></tr><tr ><td >"
     "  <p>golf</p></td><td >"
     "  <p>hotel</p></td></tr></table>")))

;; <> Use `rexp-case-fold' here once it's fixed.
(add-rexp-transform! 'line-break
    (rexp-sequence "[[" (rexp-alternatives "br" "BR") "]]")
  (lambda (registers string)
    (br)))

(define-html-template (monospace body) ()
  ((span class "monospace") body))

(add-rexp-transform! 'monospace-backquote
    (rexp-sequence "`"
		   (rexp-group
		    (rexp+
		     (char-set-invert
		      (char-set #\` #\return #\newline))))
		   "`")
  (lambda (registers string)
    (monospace (re-match-extract string registers 1))))

(define-test (wiki monospace-curly-interline)
  (check-wiki-transform
   wiki-process-string
   (string-append "<span class=\"monospace\">foo\n</span>"
		  "\n<p>bar</p>"
		  "<span class=\"monospace\">''baz''\n</span>")
   "\n{{{\nfoo\n}}}\nbar\n{{{\n''baz''\n}}}\n"))

(add-rexp-transform! 'monospace-curly-intraline
    (rexp-sequence "{{{" (rexp-group (rexp+ (rexp-any-char))) "}}}")
  (lambda (registers string)
    (monospace (re-match-extract string registers 1))))

(define-test (wiki monospace-curly-intraline)
  (check-wiki-transform
   wiki-transform
   "<span class=\"monospace\">foo</span>"
   "{{{foo}}}"))

(define ((paired-markup markup) string start)
  (let* ((markup-length (string-length markup))
	 (size (string-length string))
	 (j (substring-search-forward markup string start size)))
    (and j
	 (not (= j (- size markup-length)))
	 (not (char=? #\' (string-ref string (+ j markup-length))))
	 (let try ((offset (+ j markup-length 1)))
	   (and (< offset size)
		(let ((k (substring-search-forward markup
						   string
						   offset
						   size)))
		  (and k
		       (if (or (= k (- size markup-length))
			       (not
				(char=? #\'
					(string-ref string
						    (+ k markup-length)))))
			   (make-wiki-transform-result
			    (cons (+ j markup-length) k)
			    j
			    (+ k markup-length))
			   (try (+ k markup-length 1))))))))))

(define ((paired-markup-transform write) result string)
  (let ((data (wtr/data result)))
    (write (wiki-transform (substring string (car data) (cdr data))))))

(add-transform! 'asterisks-bold (paired-markup "**")
  (paired-markup-transform b))

(add-transform! 'asterisks-bold-italic (paired-markup "**''")
  (paired-markup-transform (lambda (body) (b (i body)))))

(add-transform! 'asterisks-italic (paired-markup "//")
  (paired-markup-transform i))

(add-transform! 'quotes-bold (paired-markup "'''")
  (paired-markup-transform b))

(add-transform! 'quotes-italic (paired-markup "''")
  (paired-markup-transform i))

(define-test (wiki bold-italic-mix)
  (check-wiki-transform
   wiki-transform
   "<i>italic and <b> italic bold </b> </i>"
   "''italic and ''' italic bold ''' ''"))

(add-rexp-transform! 'quotes-bold-italic
    (rexp-sequence "'''''" (rexp-group (rexp+ (rexp-any-char))) "'''''")
  (lambda (registers string)
    (b (i (wiki-transform (re-match-extract string registers 1))))))

(define-test (wiki bold-italic)
  (check-wiki-transform
   wiki-transform
   "<b><i>foo </i></b>"
   "'''''foo '''''"))

(add-rexp-transform! 'quotes-bold-not (rexp-sequence "!'''")
  (lambda (registers string)
    "'''"))

(define-test (wiki quotes-bold-not)
  (check-wiki-transform wiki-transform "''' foo '''" "!''' foo '''"))

(add-transform! 'strikethrough (paired-markup "~~")
  (paired-markup-transform del))

(add-transform! 'subscript (paired-markup ",,")
  (paired-markup-transform sub))

(define-test (wiki subscript)
  (check-wiki-transform
   wiki-transform
   "<sub>foo</sub> bar <sub>baz</sub>"
   ",,foo,, bar ,,baz,,"))

(add-transform! 'superscript (paired-markup "^")
  (paired-markup-transform sup))

(define-test (wiki superscript)
  (check-wiki-transform
   wiki-transform
   "<sup>foo</sup> bar <sup>baz</sup>"
   "^foo^ bar ^baz^"))

(add-rexp-transform! 'superscript
    (rexp-sequence "^"
		   (rexp-group (rexp+ (char-set-invert (char-set #\^))))
		   "^")
  (lambda (registers string)
    (sup (wiki-transform (re-match-extract string registers 1)))))

(define-test (wiki superscript)
  (check-wiki-transform
   wiki-transform
   "<sup>foo</sup>bar<sup>baz</sup>"
   "^foo^bar^baz^"))

(add-rexp-transform! 'ticket-link
    (rexp-sequence "ticket:"
		   (rexp-group (rexp+ char-set:numeric)))
  (lambda (registers string)
    (href-simple (re-match-extract string registers 0)
		 (format #f
			 "/ticket/~A"
			 (re-match-extract string registers 1)))))

(add-rexp-transform! 'ticket-pound-link
    (rexp-sequence "#"
		   (rexp-group (rexp+ char-set:numeric)))
  (lambda (registers string)
    (href-simple (re-match-extract string registers 0)
		 (format #f
			 "/ticket/~A"
			 (re-match-extract string registers 1)))))

(add-transform! 'underline (paired-markup "__")
  (paired-markup-transform u))

(define-test (wiki underline)
  (check-wiki-transform
   wiki-transform
   "<u>foo</u> bar <u>baz</u>"
   "__foo__ bar __baz__"))

(define (wiki-sort-matches matches)
  (sort matches
	(lambda (m1 m2)
	  (let* ((wtr1 (car m1))
		 (wtr2 (car m2))
		 (s1 (wtr/start wtr1))
		 (s2 (wtr/start wtr2)))
	    (if (= s1 s2)
		(> (wtr/end wtr1) (wtr/end wtr2))
		(< s1 s2))))))

(define (wiki-transform string)
  (define (wiki-try-transform transform start)
    (let ((result ((wt/search transform) string start)))
      (and result
	   (let ((guard (wt/guard transform)))
	     (and (or (not guard)
		      (guard result string))
		  (cons result transform))))))
  (let next-match ((accumulator '())
		   (i 0)
		   (matches
		    (wiki-sort-matches
		     (remove not
			     (map (lambda (wt) (wiki-try-transform wt 0))
				  wiki-transforms)))))
    (if (null? matches)
	(reverse! (cons (string-tail string i) accumulator))
	(let* ((result (caar matches))
	       (transform (cdar matches))
	       (start (wtr/start result))
	       (end (wtr/end result)))
	  (let-values (((beyond overlap)
			(collate
			 matches
			 (lambda (m)
			   (and (<= end (wtr/start (car m)))
				m)))))
	    (next-match (cons* ((wt/transform transform) result string)
			       (substring string i start)
			       accumulator)
			end
			(wiki-sort-matches
			 (append
			  (remove not
				  (map (lambda (m)
					 (wiki-try-transform (cdr m) end))
				       overlap))
			  beyond))))))))

(define (wiki-split-at offset regexp string)
  (let* ((size (string-length string))
	 (registers (re-substring-search-forward regexp string offset size)))
    (and registers
	 (cons (re-match-start-index 0 registers)
	       (re-match-end-index 0 registers)))))

(define non-paragraph-start
  (rexp-alternatives citation-line headline-line outline-line table-line))

(define paragraph-end (rexp-alternatives non-paragraph-start paragraph-break))

(define (skip-forward regexp)
  (lambda (string start end)
    (let ((registers (re-substring-match regexp string start end)))
      (if registers
	  (re-match-end-index 0 registers)
	  start))))

(define skip-blank-lines
  (skip-forward
   (rexp-compile
    (rexp-sequence (rexp* (char-set #\space #\tab))
		   line-break))))

(define term-line
  (rexp-sequence
   (rexp-line-start)
   " "
   (rexp-group (rexp+ (char-set-invert (char-set #\return #\newline))))
   "::"
   (rexp* (char-set #\space #\tab))
   line-break))

(define definition-line
  (rexp-sequence
   (rexp+ (char-set #\space #\tab))
   (rexp-group (rexp+ (char-set-invert (char-set #\return #\newline))))
   (rexp-optional line-break)))

;; <> This is implemented this way because MIT Scheme 9.2.1 has a bug
;; that makes regular expression matching fail when these particular
;; regular expressions are combined using `rexp-alternatives'.  I
;; haven't yet found a minimal reproducible case suitable for
;; including in a bug report.
(define find-paragraph-end
  (let ((regexps (cons open-re
		       (map rexp-compile
			    (list citation-line
				  headline-line
				  outline-line
				  paragraph-break
				  table-line
				  term-line)))))
    (lambda (string start end)
      (let* ((offset (skip-blank-lines string start end))
	     (registers
	      (filter
	       (lambda (r) r)
	       (map (lambda (re)
		      (cond ((re-substring-search-forward re string offset end)
			     => (lambda (r) (re-match-start-index 0 r)))
			    (else #f)))
		    regexps))))
	(if (null? registers)
	    end
	    (extremum registers < end))))))

(define read-single-definition
  (let ((definition-regexp (rexp-compile definition-line))
	(term-regexp (rexp-compile term-line)))
    (lambda (string start end)
      (let ((term (re-substring-match term-regexp string start end)))
	;; Read until <end>, the next <definition>, or the first line
	;; that doesn't start with whitespace, whichever comes first,
	;; accumulating the definition-regexp of the term we just saw.
	(if term
	    (let next ((accumulator '())
		       (i (re-match-end-index 0 term)))
	      (let ((j (skip-blank-lines string i end)))
		(define (finish)
		  (values (compose-two-writers
			   (dt (wiki-transform
				(re-match-extract string term 1)))
			   (dd (wiki-transform (string-join
						"\n"
						(reverse! accumulator)))))
			  j))
		(cond ((or (= j end)
			   (re-substring-match term-regexp string j end))
		       (finish))
		      ((re-substring-match definition-regexp string j end)
		       => (lambda (registers)
			    (next (cons (re-match-extract string registers 1)
					accumulator)
				  (re-match-end-index 0 registers))))
		      (else (finish)))))
	    (values #f start))))))

(define (transform-definitions string start end)
  (let ((limit (find-paragraph-end string start end)))
    (let next ((accumulator '())
	       (index start))
      (let-values (((def offset) (read-single-definition string index end)))
	(if def
	    (next (cons def accumulator)
		  (skip-blank-lines string offset end))
	    (values (dl (apply compose-writers (reverse! accumulator)))
		    offset))))))

;; Break `string' into paragraphs and non-paragraphs and transform
;; each appropriately.
(define wiki-process-regions
  (let* ((blockquote (rexp-compile blockquote-line))
	 (citation (rexp-compile citation-line))
	 (term (rexp-compile term-line))
	 (headline (rexp-compile headline-line))
	 (outline (rexp-compile outline-line))
	 (table (rexp-compile table-line))
	 (transformers
	  (list (cons citation transform-citation)
		(cons open-re transform-curlies)
		(cons term transform-definitions)
		(cons outline transform-outline) ; Match before blockquote.
		(cons blockquote transform-blockquote)
		(cons headline transform-headline)
		(cons table transform-table))))
    (lambda (string start end)
      (let next ((accumulator '())
		 (i start))
	(cond ((>= i end) (reverse! accumulator))
	      ((find (lambda (xfm) (re-substring-match (car xfm) string i end))
		     transformers)
	       => (lambda (xfm)
		    (let-values (((result offset) ((cdr xfm) string i end)))
		      (next (cons result accumulator)
			    offset))))
	      (else
	       (let* ((break (find-paragraph-end string i end))
		      (paragraph (string-trim (substring string i break))))
		 (next (if (string-whitespace? paragraph)
			   accumulator
			   (cons (p (wiki-transform paragraph))
				 accumulator))
		       break))))))))

(define (wiki-process-string string)
  (wiki-process-regions string 0 (string-length string)))

(define-record-type wiki-processor
    (make-wiki-processor name transform)
    processor?
  (name wp/name)
  (transform wp/transform))

(define wiki-processors '())

(define (add-processor! name transform)
  (set! wiki-processors
	(cons (make-wiki-processor name transform)
	      (remove (lambda (wp) (string=? name (wp/name wp)))
		      wiki-processors)))
  name)

(define (processor-whole-contents rest string)
  (substring string (caar rest) (cdar (last-pair rest))))

(define (preformatted-processor descend parameters rest string)
  (monospace (processor-whole-contents rest string)))

(define (raw-processor descend parameters rest string)
  (write-raw-string (processor-whole-contents rest string)))

(add-processor! "" preformatted-processor)

(add-processor! "comment" (lambda (descend parameters rest string) ""))

(add-processor! "html" raw-processor)	; Does not sanitize HTML.
(add-processor! "xml" raw-processor)	; Does not sanitize HTML.

(define (make-html-tag-processor tag)
  (lambda (descend parameters rest string)
    (list (write-raw-string (format #f "<~A ~A>" tag parameters))
	  (map descend rest)
	  (write-raw-string (format #f "</~A>" tag)))))

(add-processor! "div" (make-html-tag-processor "div"))
(add-processor! "table" (make-html-tag-processor "table"))
(add-processor! "td" (make-html-tag-processor "td"))
(add-processor! "th" (make-html-tag-processor "th"))
(add-processor! "tr" (make-html-tag-processor "tr"))

(define-test (wiki-process-string)
  (check-wiki-transform
   wiki-process-string
   (string-append "\n<p>foo</p>\n<p>bar</p>\n<p>baz</p>"
		  "<span class=\"monospace\">bat\nquux\n</span>"
		  "\n<p>alpha\nbravo</p>")
   "foo\n\nbar\n\nbaz\n{{{\nbat\nquux\n}}}\n\nalpha\nbravo")
  (check-wiki-transform
   wiki-process-string
   (string-append "\n<h1 id=\"foo\">foo</h1>\n<p>alpha</p>"
		  "\n<h1 id=\"bar\">bar</h1>\n<p>bravo</p>"
		  "\n<p>charlie\ndelta</p>")
   "= foo =\nalpha\n\n= bar =\nbravo\n\ncharlie\ndelta"))

(define (collect-wiki-transform string xfm)
  (with-output-to-string
    (lambda ()
      (invoke-writer (xfm string)))))

(define (check-wiki-transform xfm expected string)
  (assert (string=? expected (collect-wiki-transform string xfm))))

(define (test string)
  (collect-wiki-transform string wiki-process-string))