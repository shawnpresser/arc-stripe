(load "test.arc")

(= user-uid* 1000)

(let port 8080
  (when (> (len cmdline*) 0)
    (= port (coerce (cmdline* 0) 'int)))
  (tsv port))

