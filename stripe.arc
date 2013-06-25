
(= safechars* (+ "abcdefghijklmnopqrstuvwxyz"
                 "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                 "1234567890_-.@ "))

(def escparm (x (o morechars))
  (with (cmd (coerce x 'string)
         s   nil)
    (each c cmd
      (let p (positions c (string safechars* morechars))
        (when p (push c s))))
    (coerce (rev s) 'string)))

(= noisy-stripe* nil)

(def stripe-call (api u parms (o flag))
  (let params nil
    (each (k v) parms
      ((afn (k v)
         (when v
           (if (alist v)
               (each (vk vv) v
                 (self (string k "[" vk "]") vv))
               (do
                 (push (string " -d "
                               #\" (escparm k "[]") "=" (escparm v) #\")
                       params)))))
       k v))
    (let cmd (+ "curl -k "
                (if (is flag 'get)    "-G "
                    (is flag 'post)   "-X POST "
                    (is flag 'delete) "-X DELETE ")
                api
                " -u "(escparm u)":"
                (string (rev params)))
      (when noisy-stripe*
        (prn cmd))
      (let (stout sterr) (tostrings (system cmd))
        stout))))

;
; Charges
;

(def stripe-new-charge (u amt currency (o cust) (o card) (o desc)
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

(def stripe-new-plan (u id name amt currency interval interval_count
                        (o trial_period_days))
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

(def stripe-get-invoiceitems (u (o num 10) (o off 0) (o cust) 
                                (o created))
  (stripe-call "https://api.stripe.com/v1/invoiceitems"
               u 
               `((count          ,num)
                 (offset         ,off)
                 (customer       ,cust)
                 (created        ,created))
               'get))

;
; Recipients
;

(def stripe-new-recipient (u name type (o tax-id) (o bank) (o email)
                             (o desc))
  (stripe-call "https://api.stripe.com/v1/recipients"
               u 
               `((name              ,name)
                 (type              ,type)
                 (tax_id            ,tax-id)
                 (bank_account      ,bank)
                 (email             ,email)
                 (description       ,desc))
               'post))

(def stripe-get-recipient (u id)
  (stripe-call (+ "https://api.stripe.com/v1/recipients/"
                  (escparm id))
               u 
               nil
               'get))

(def stripe-update-recipient (u id name type (o tax-id) (o bank)
                                (o email) (o desc))
  (stripe-call (+ "https://api.stripe.com/v1/recipients/"
                  (escparm id))
               u 
               `((name              ,name)
                 (type              ,type)
                 (tax_id            ,tax-id)
                 (bank_account      ,bank)
                 (email             ,email)
                 (description       ,desc))
               'post))

(def stripe-delete-recipient (u id)
  (stripe-call (+ "https://api.stripe.com/v1/recipients/"
                  (escparm id))
               u 
               nil
               'delete))

(def stripe-get-recipients (u (o num 10) (o off 0) (o verified))
  (stripe-call "https://api.stripe.com/v1/recipients"
               u 
               `((count          ,num)
                 (offset         ,off)
                 (verified       ,verified))
               'get))

;
; Transfers
;

(def stripe-new-transfer (u amt currency recipient (o desc)
                            (o stmt-desc))
  (stripe-call "https://api.stripe.com/v1/transfers"
               u 
               `((amount               ,amt)
                 (currency             ,currency)
                 (recipient            ,recipient)
                 (description          ,desc)
                 (statement_descriptor ,stmt-desc))
               'post))

(def stripe-get-transfer (u id)
  (stripe-call (+ "https://api.stripe.com/v1/transfers/"
                  (escparm id))
               u 
               nil
               'get))

(def stripe-cancel-transfer (u id)
  (stripe-call (+ "https://api.stripe.com/v1/transfers/"
                  (escparm id) "/cancel")
               u 
               nil
               'post))

(def stripe-get-transfers (u (o num 10) (o off 0) (o recipient)
                             (o date) (o status))
  (stripe-call "https://api.stripe.com/v1/transfers"
               u 
               `((count          ,num)
                 (offset         ,off)
                 (recipient      ,recipient)
                 (date           ,date)
                 (status         ,status))
               'get))

;
; Account
;

(def stripe-account (u)
  (stripe-call "https://api.stripe.com/v1/account"
               u 
               nil
               'get))

;
; Balance
;

(def stripe-balance (u)
  (stripe-call "https://api.stripe.com/v1/balance"
               u 
               nil
               'get))

(def stripe-get-balances (u (o num 10) (o off 0) (o type) (o transfer)
                            (o avail-on) (o created))
  (stripe-call "https://api.stripe.com/v1/balance/history"
               u 
               `((count          ,num)
                 (offset         ,off)
                 (type           ,type)
                 (transfer       ,transfer)
                 (available_on   ,avail-on)
                 (created        ,created))
               'get))

;
; Events
;

(def stripe-event (u)
  (stripe-call (+ "https://api.stripe.com/v1/events/"
                  (escparm id))
               u 
               nil
               'get))

(def stripe-get-events (u (o num 10) (o off 0) (o type) (o created))
  (stripe-call "https://api.stripe.com/v1/events"
               u 
               `((count          ,num)
                 (offset         ,off)
                 (type           ,type)
                 (created        ,created))
               'get))

