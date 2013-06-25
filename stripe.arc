
(= safechars* (+ "abcdefghijklmnopqrstuvwxyz"
                 "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                 "1234567890_-.@ "))

(def escparm (x)
  (with (cmd (coerce x 'string)
         s   nil)
    (each c cmd
      (let p (positions c safechars*)
        (when p (push c s))))
    (coerce (rev s) 'string)))


(def stripe-call (api u parms)
  (let strs nil
    (each (k v) parms
      (let s (escparm (coerce v 'string))
        (when (positions #\space s)
          (= s (+ "\"" s "\"")))
        (push (+ " -d "
                 (coerce k 'string)
                 "="
                 s)
              strs)))
    (let (stout sterr) (tostrings
                         (system (+
                                   "curl -k "api
                                   " -u "(escparm u)":"
                                   (coerce (rev strs) 'string))))
      stout)))

(def stripe-charge (u amt tok desc)
  (stripe-call "https://api.stripe.com/v1/charges"
               u 
               `((amount      ,amt)
                 (currency     usd)
                 (card        ,tok)
                 (description ,desc))))



