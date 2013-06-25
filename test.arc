(load "stripe.arc")

(= user-uid*  1000
   stripekey* "pk_test_xaFf1GeaSmeg3wRg6YPNX9Dg"
   stripesec* "sk_test_YHFBf5rTlYikjw1GeDCbCLvt")

(deftem pay
  id          nil
  by          nil
  ip          nil
  time        (msec)
  action      nil  ; charge, refund, ...
  processor   nil  ; stripe, wepay, amazon, ...
  result      nil) ; stripe JSON, ...

(= paydir* "arc/pay/")

(def tsv ((o port 8080))
  (push paydir* srvdirs*)
  (unless (> (len pays*) 0) (load-pays))
  (asv port))

(= pays* (table) maxpayid* 0)

(def load-pays ()
  (system (+ "rm " paydir* "*.tmp"))
  (pr "load payments: ")
  (with (pays nil
         ids  (sort > (map int (dir paydir*))))
    (if ids (= maxpayid* (car ids)))
    (noisy-each 100 id ids
      (let p (load-pay id)
        (push p pays)))))

(def load-pay (id)
  (= (pays* id) (temload 'pay (+ paydir* id))))

(def new-pay-id ()
  (evtil (++ maxpayid*) [~file-exists (+ paydir* _)]))

(def pay (id)
  (or (pays* id) (errsafe:load-pay id)))

(def save-pay (p) (save-table p (+ paydir* p!id)))

(def paylog args (apply srvlog 'pay args))

(mac pay-stripe (ip u call . params)
  (w/uniq gp
    `(let ,gp (inst 'pay 'id (new-pay-id) 'by ,u 'ip ,ip 'action ',call
                    'processor 'stripe 'result (,call stripesec* ,@params))
       (save-pay ,gp)
       (= (,gp 'ret) (jsondec (,gp 'result)))
       (= (pays* (,gp 'id)) ,gp)
       ,gp)))

(def create-customer (ip u card)
  (paylog ip u 'stripe 'newcust)
  (pay-stripe ip u stripe-new-customer card))

(def create-charge (ip u amt card)
  (paylog ip u 'stripe 'charge amt)
  (withs (c  (create-customer ip u card)
          id (c!ret "id"))
    (unless id (err "Charge failed"))
    (pay-stripe ip u stripe-new-charge amt "usd" id)))

(def display-pay-number (n)
  (when n (tag (td align 'right valign 'top class 'title)
            (pr n "."))))

(mac tdrt body `(tag (td align 'right valign 'top) ,@body))

(def display-pay (p)
  (tr (display-pay-number p!id)
      (tdrt (pr p!time))
      (tdrt (pr p!ip))
      (tdrt (pr p!by))
      (tdrt (pr p!processor))
      (tdrt (pr p!action))
      (td (tag pre (pr (multisubst `(("\n" "<br>") (" " "&nbsp;")) p!result))))))

(def display-pays (pays (o start 0) (o end))
  (tab
    (each p (cut (rev pays) start end)
      (display-pay p)
      (spacerow 5))))

(def pays ((o keepfn [do t]))
  (let xs nil
    (each (id p) pays*
      (when (keepfn p)
        (push p xs)))
    (sort (compare < [do _!id]) xs)))

; Page top

(= sand (color 246 246 239) textgray (gray 130))

(def gen-css-url ())

(= jqueryjs* "
<script type=\"text/javascript\" src=\"http://code.jquery.com/jquery-2.0.2.min.js\"></script>
")

(= stripejs* (+ "
<script type=\"text/javascript\" src=\"https://js.stripe.com/v2/\"></script>
<script type=\"text/javascript\">

Stripe.setPublishableKey('"stripekey*"');

var stripeResponseHandler = function(status, response) {
  var $form = $('#payment-form');

  if (response.error) {
    // Show the errors on the form
    $form.find('.payment-errors').text(response.error.message);
    $form.find('button').prop('disabled', false);
  } else {
    // token contains id, last4, and card type
    var token = response.id;
    // Insert the token into the form so it gets submitted to the server
    $form.append($('<input type=\"hidden\" name=\"stripeToken\" />').val(token));
    // and submit
    $form.get(0).submit();
  }
};

jQuery(function($) {
  $('#payment-form').submit(function(event) {
    var $form = $(this);

    // Disable the submit button to prevent repeated clicks
    $form.find('button').prop('disabled', true);

    Stripe.createToken($form, stripeResponseHandler);

    // Prevent the form from submitting with the default action
    return false;
  });
});
</script>

"))

; Site-Specific Defop Variants

(def ensure-user (u))

(mac defopt (name parm test msg . body)
  `(defop ,name ,parm
     (if (,test (get-user ,parm))
         (do ,@body)
         (login-page 'both (+ "Please log in" ,msg ".")
                     (list (fn (u ip) (ensure-user u))
                           (string ',name (reassemble-args ,parm)))))))

(mac defopg (name parm . body)
  `(defopt ,name ,parm idfn "" ,@body))

(mac defope (name parm . body)
  `(defopt ,name ,parm editor " as an editor" ,@body))

(mac defopa (name parm . body)
  `(defopt ,name ,parm admin " as an administrator" ,@body))

(mac aform2 (id f . body)
  (w/uniq ga
    `(tag (form id ,id method 'post action fnurl*)
       (fnid-field (fnid (fn (,ga)
                           (prn)
                           (,f ,ga))))
       ,@body)))

(mac npage (title . body)
  `(tag html 
     (tag head 
       (gen-css-url)
       ;(prn "<link rel=\"shortcut icon\" href=\"" favicon-url* "\">")
       (pr jqueryjs*)
       (pr stripejs*)
       (tag title (pr ,title)))
     (tag body 
       (center
         (tag (table border 0 cellpadding 0 cellspacing 0 width "85%"
                     bgcolor sand)
           ,@body)))))

(defopg test req
  (npage "Test"
    (trtd
      (aform2 'payment-form
              (fn (req)
                 (pr req)
                 (br 2)
                 (write 
                   (create-charge req!ip
                                  (get-user req)
                                  1000
                                  (arg req "stripeToken"))))
        (zerotable
          (tr (spanrow 2 (center (spanclass "payment-errors" (pr "errors go here")))))
          (tr
            (tdr (tag span (pr "Card Number")))
            (td  (gentag input type "text" size 20 data-stripe 'number)))
          (tr
            (tdr (tag span (pr "Security Code")))
            (td  (gentag input type "text" size 4 data-stripe 'cvc)))
          (tr
            (tdr (tag span (pr "Expiration (MM/YYYY)")))
            (td  (gentag input type "text" size 2 data-stripe 'exp-month)
              (tag span (pr " / "))
              (gentag input type "text" size 4 data-stripe 'exp-year))))
        (but "Submit Payment")))))

(defopa pays req
  (npage "Payments"
    (trtd
      (display-pays (pays)))))

