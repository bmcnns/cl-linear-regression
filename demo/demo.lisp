(require :asdf)
(push (merge-pathnames "../" (make-pathname :name nil :type nil :defaults *load-truename*)) asdf:*central-registry*)
(asdf:load-system "cl-linear-regression")

(defparameter *degree* 9 "The polynomial's degree.")
(defparameter *samples* 15 "Noisy samples of the target.")
(defparameter *noise* 0.2d0 "The samples' noise (standard deviation).")
(defparameter *ridges* (loop for e from -9 to 2 by 1/2 collect (expt 10d0 e)) "The ridge penalties, one per frame.")
(defparameter *curve-points* 200 "Points each fitted curve is drawn with.")

(defun target (x)
  "The function the samples come from."
  (sin (* pi x)))

(defun normal (random-state)
  "A standard normal sample (Box-Muller)."
  (* (sqrt (* -2 (log (- 1d0 (random 1d0 random-state))))) (cos (* 2 pi (random 1d0 random-state)))))

(defun features (xs)
  "The polynomial features x, x^2, ... x^*DEGREE* of each of XS, as a matrix."
  (let ((out (make-array (list (length xs) *degree*) :element-type 'double-float)))
    (loop for x in xs for r from 0
          do (dotimes (k *degree*) (setf (aref out r k) (expt x (1+ k)))))
    out))

(defun samples (seed)
  "*SAMPLES* noisy samples of TARGET on [-1, 1]: their xs and ys."
  (let* ((rs (sb-ext:seed-random-state seed))
         (xs (loop repeat *samples* collect (- (random 2d0 rs) 1d0))))
    (values xs (mapcar (lambda (x) (+ (target x) (* *noise* (normal rs)))) xs))))

(defun curve-xs ()
  "The xs each curve is drawn at."
  (loop for i below *curve-points* collect (- (* 2d0 (/ i (1- *curve-points*))) 1d0)))

(multiple-value-bind (xs ys) (samples 4)
  (let ((x (features xs)) (y (coerce ys 'vector)) (grid (features (curve-xs))))
    (with-open-file (out (merge-pathnames "samples.dat" *load-truename*) :direction :output :if-exists :supersede)
      (loop for a in xs for b in ys do (format out "~,6F ~,6F~%" a b)))
    (with-open-file (out (merge-pathnames "fits.dat" *load-truename*) :direction :output :if-exists :supersede)
      (dolist (ridge *ridges*)
        (let ((curve (lr:predict (lr:fit x y :ridge ridge) grid)))
          (format out "# ridge ~,3E~%" ridge)
          (loop for a in (curve-xs) for i from 0
                do (format out "~,6F ~,6F ~,6F~%" a (aref curve i 0) (target a)))
          (format out "~%~%"))))
    (format t "~D frames~%" (length *ridges*))))
