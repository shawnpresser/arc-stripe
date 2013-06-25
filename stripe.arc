
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


(def stripe-call (api u parms (o use-get))
  (let strs nil
    (each (k v) parms
      (when v
        (let s (escparm (coerce v 'string))
          (when (positions #\space s)
            (= s (+ "\"" s "\"")))
          (push (+ " -d "
                   (coerce k 'string)
                   "="
                   s) strs))))
    (let (stout sterr) (tostrings
                         (system (+
                                   "curl -k "
                                   (if use-get "-G ")
                                   api
                                   " -u "(escparm u)":"
                                   (coerce (rev strs) 'string))))
      stout)))

(def stripe-charge (u amt tok desc (o capture t))
  (stripe-call "https://api.stripe.com/v1/charges"
               u 
               `((amount      ,amt)
                 (currency     usd)
                 (card        ,tok)
                 (description ,desc)
                 (capture     ,(if capture "true")))))

(def stripe-get-charge (u id)
  (stripe-call (+ "https://api.stripe.com/v1/charges/"
                  (escparm id))
               u 
               nil))

(def stripe-get-charges (u (o num 10) (o off 0) (o created)
                           (o customer))
  (stripe-call "https://api.stripe.com/v1/charges"
               u 
               `((count          ,num)
                 (created        ,created)
                 (customer       ,customer)
                 (offset         ,off))
               t))

(def stripe-refund (u id (o amt) (o refund_appfee))
  (stripe-call (+ "https://api.stripe.com/v1/charges/"
                  (escparm id) "/refund")
               u 
               `((amount                 ,amt)
                 (refund_application_fee ,(if refund_appfee "true")))))

(def stripe-capture (u id (o amt) (o appfee))
  (stripe-call (+ "https://api.stripe.com/v1/charges/"
                  (escparm id) "/capture")
               u 
               `((amount                 ,amt)
                 (application_fee        ,appfee))))




