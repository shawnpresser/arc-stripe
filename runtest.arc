(load "test.arc")

(let port 8080
  (when (> (len cmdline*) 0)
    (= port (coerce (cmdline* 0) 'int)))
  (tsv port))

