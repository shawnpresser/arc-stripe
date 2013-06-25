(load "stripe.arc")

(= stripekey* "pk_test_xaFf1GeaSmeg3wRg6YPNX9Dg")
(= stripesec* "sk_test_YHFBf5rTlYikjw1GeDCbCLvt")

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


(defop test req
  (npage "Test"
    (trtd
      (aform2 'payment-form
              (fn (req)
                 (pr req)
                 (br 2)
                 (write 
                   (stripe-charge stripesec*
                                  1000
                                  (arg req "stripeToken")
                                  "test charge.")))
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

(def tsv ((o port 8080))
  (asv port))

