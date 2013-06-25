
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


(def stripe-call (api u parms (o flag))
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
                                   (if (is flag 'get)    "-G "
                                       (is flag 'post)   "-X POST "
                                       (is flag 'delete) "-X DELETE ")
                                   api
                                   " -u "(escparm u)":"
                                   (coerce (rev strs) 'string))))
      stout)))

;
; Charges
;

(def stripe-new-charge (u amt tok desc (o currency "usd")
                          (o capture t))
  (stripe-call "https://api.stripe.com/v1/charges"
               u 
               `((amount         ,amt)
                 (currency       ,currency)
                 (card           ,tok)
                 (description    ,desc)
                 (capture        ,(if capture "true")))
               'post))

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
               'get))

(def stripe-refund (u id (o amt) (o refund_appfee))
  (stripe-call (+ "https://api.stripe.com/v1/charges/"
                  (escparm id) "/refund")
               u 
               `((amount                 ,amt)
                 (refund_application_fee ,(if refund_appfee "true")))
               'post))

(def stripe-capture (u id (o amt) (o appfee))
  (stripe-call (+ "https://api.stripe.com/v1/charges/"
                  (escparm id) "/capture")
               u 
               `((amount                 ,amt)
                 (application_fee        ,appfee))
               'post))

;
; Customers
;

(def stripe-new-customer (u (o card) (o coupon) (o email) (o desc)
                            (o balance) (o plan) (o trial_end)
                            (o quantity))
  (stripe-call "https://api.stripe.com/v1/customers"
               u 
               `((card            ,card)
                 (coupon          ,coupon)
                 (email           ,email)
                 (description     ,desc)
                 (account_balance ,balance)
                 (plan            ,plan)
                 (trial_end       ,trial_end)
                 (quantity        ,quantity))
               'post))

(def stripe-get-customer (u id)
  (stripe-call (+ "https://api.stripe.com/v1/customers/"
                  (escparm id))
               u 
               nil
               'get))

(def stripe-update-customer (u id (o card) (o coupon) (o desc)
                               (o balance) (o email))
  (stripe-call (+ "https://api.stripe.com/v1/customers/"
                  (escparm id))
               u 
               `((card            ,card)
                 (coupon          ,coupon)
                 (email           ,email)
                 (description     ,desc)
                 (account_balance ,balance))))

(def stripe-delete-customer (u id)
  (stripe-call (+ "https://api.stripe.com/v1/customers/"
                  (escparm id))
               u 
               nil
               'delete))

(def stripe-get-customers (u (o num 10) (o off 0) (o created))
  (stripe-call "https://api.stripe.com/v1/customers"
               u 
               `((count          ,num)
                 (created        ,created)
                 (offset         ,off))
               'get))

;
; Plans
;

(def stripe-new-plan (u id name amt interval interval_count
                        (o currency "usd") (o trial_period_days))
  (stripe-call "https://api.stripe.com/v1/plans"
               u 
               `((id                ,id)
                 (name              ,name)
                 (amount            ,amt)
                 (currency          ,currency)
                 (interval          ,interval)
                 (interval_count    ,interval_count)
                 (trial_period_days ,trial_period_days))
               'post))

(def stripe-get-plan (u id)
  (stripe-call (+ "https://api.stripe.com/v1/plans/"
                  (escparm id))
               u 
               nil
               'get))

(def stripe-update-plan (u id name)
  (stripe-call (+ "https://api.stripe.com/v1/plans/"
                  (escparm id))
               u 
               `((name              ,name))
               'post))

(def stripe-delete-plan (u id)
  (stripe-call (+ "https://api.stripe.com/v1/plans/"
                  (escparm id))
               u 
               nil
               'delete))

(def stripe-get-plans (u (o num 10) (o off 0) (o created))
  (stripe-call "https://api.stripe.com/v1/plans"
               u 
               `((count          ,num)
                 (offset         ,off))
               'get))


