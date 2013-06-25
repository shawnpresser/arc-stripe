
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

(def stripe-new-charge (u amt (o cust) (o card) (o desc)
                          (o currency "usd")
                          (o capture t)
                          (o appfee))
  (stripe-call "https://api.stripe.com/v1/charges"
               u 
               `((amount          ,amt)
                 (currency        ,currency)
                 (customer        ,cust)
                 (card            ,card)
                 (description     ,desc)
                 (application_fee ,appfee)
                 (capture         ,(if capture "true")))
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

(def stripe-new-customer (u (o card) (o email) (o desc) (o balance)
                            (o coupon) (o plan) (o trial-end)
                            (o quantity))
  (stripe-call "https://api.stripe.com/v1/customers"
               u 
               `((card            ,card)
                 (coupon          ,coupon)
                 (email           ,email)
                 (description     ,desc)
                 (account_balance ,balance)
                 (plan            ,plan)
                 (trial_end       ,trial-end)
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

(def stripe-get-plans (u (o num 10) (o off 0))
  (stripe-call "https://api.stripe.com/v1/plans"
               u 
               `((count          ,num)
                 (offset         ,off))
               'get))


;
; Subscriptions
;

(def stripe-update-sub (u cust plan (o coupon) (o prorate t)
                          (o trial-end) (o quantity) (o card))
  (stripe-call (+ "https://api.stripe.com/v1/customers/"
                  (escparm cust) "/subscription")
               u
               `((plan              ,plan)
                 (coupon            ,coupon)
                 (prorate           ,(if prorate "true"))
                 (trial_end         ,trial-end)
                 (quantity          ,quantity)
                 (card              ,card))
               'post))

(def stripe-cancel-sub (u cust (o at_period_end))
  (stripe-call (+ "https://api.stripe.com/v1/customers/"
                  (escparm cust) "/subscription")
               u
               `((at_period_end     ,at_period_end))
               'delete))

;
; Coupons
;

(def stripe-new-coupon (u dur (o id) (o amt-off) (o currency)
                          (o perc-off) (o dur-months) (o max-redemps) 
                          (o redeem-by))
  (stripe-call "https://api.stripe.com/v1/coupons"
               u 
               `((id                 ,id)
                 (duration           ,dur)
                 (amount_off         ,amt-off)
                 (currency           ,currency)
                 (percent_off        ,perc-off)
                 (duration_in_months ,dur-months)
                 (max_redemptions    ,max-redemps)
                 (redeem_by          ,redeem-by))
               'post))

(def stripe-get-coupon (u id)
  (stripe-call (+ "https://api.stripe.com/v1/coupons/"
                  (escparm id))
               u 
               nil
               'get))

(def stripe-delete-coupon (u id)
  (stripe-call (+ "https://api.stripe.com/v1/coupons/"
                  (escparm id))
               u 
               nil
               'delete))

(def stripe-get-coupons (u (o num 10) (o off 0))
  (stripe-call "https://api.stripe.com/v1/coupons"
               u 
               `((count          ,num)
                 (offset         ,off))
               'get))

;
; Discounts
;

(def stripe-delete-coupon (u cust)
  (stripe-call (+ "https://api.stripe.com/v1/customers/"
                  (escparm cust) "/discount")
               u 
               nil
               'delete))

;
; Invoices
;

(def stripe-get-invoice (u id)
  (stripe-call (+ "https://api.stripe.com/v1/invoices/"
                  (escparm id))
               u 
               nil
               'get))

(def stripe-get-invoice-lines (u id (o cust) (o num 10) (o off 0))
  (stripe-call (+ "https://api.stripe.com/v1/invoices/"
                  (escparm id) "/lines")
               u 
               `((id                 ,id)
                 (customer           ,cust)
                 (count              ,num)
                 (offset             ,off))
               'get))

(def stripe-new-invoice (u cust)
  (stripe-call "https://api.stripe.com/v1/invoices"
               u 
               `((cust               ,cust))
               'post))

(def stripe-pay-invoice (u id)
  (stripe-call (+ "https://api.stripe.com/v1/invoices/"
                  (escparm id) "/pay")
               u 
               nil
               'post))

(def stripe-update-invoice (u id closed)
  (stripe-call (+ "https://api.stripe.com/v1/invoices/"
                  (escparm id))
               u 
               `((closed             ,(if closed "true" "false")))
               'post))

(def stripe-delete-invoice (u id)
  (stripe-call (+ "https://api.stripe.com/v1/invoices/"
                  (escparm id))
               u 
               nil
               'delete))

(def stripe-get-invoices (u (o cust) (o num 10) (o off 0) (o date))
  (stripe-call "https://api.stripe.com/v1/invoices"
               u 
               `((count          ,num)
                 (offset         ,off)
                 (customer       ,cust)
                 (date           ,date))
               'get))

(def stripe-get-upcoming-invoices (u (o cust))
  (stripe-call "https://api.stripe.com/v1/invoices/upcoming"
               u 
               `((customer       ,cust))
               'get))


;
; Invoice Items
;

(def stripe-new-invoiceitem (u cust amt currency (o inv) (o desc))
  (stripe-call "https://api.stripe.com/v1/invoiceitems"
               u 
               `((customer          ,cust)
                 (amount            ,amt)
                 (currency          ,currency)
                 (invoice           ,inv)
                 (description       ,desc))
               'post))

(def stripe-get-invoiceitem (u id)
  (stripe-call (+ "https://api.stripe.com/v1/invoiceitems/"
                  (escparm id))
               u 
               nil
               'get))

(def stripe-update-invoiceitem (u amt desc)
  (stripe-call (+ "https://api.stripe.com/v1/invoiceitems/"
                  (escparm id))
               u 
               `((amount            ,amt)
                 (description       ,desc))
               'post))

(def stripe-delete-invoiceitem (u id)
  (stripe-call (+ "https://api.stripe.com/v1/invoiceitems/"
                  (escparm id))
               u 
               nil
               'delete))

(def stripe-get-invoiceitems (u (o cust) (o num 10) (o off 0)
                                (o created))
  (stripe-call "https://api.stripe.com/v1/invoiceitems"
               u 
               `((count          ,num)
                 (offset         ,off)
                 (customer       ,cust)
                 (created        ,created))
               'get))

