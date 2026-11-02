# Ridge regression of a degree-9 polynomial, the penalty swept from 1e-9 to 1e2, as an animated GIF:
#   cd demo && sbcl --script demo.lisp && gnuplot ridge.gp
# samples.dat: the noisy samples (x y). fits.dat: per penalty, a block of the fitted curve (x fit target).
# ImageMagick holds the last frame for 3 seconds.
stats "fits.dat" using 1 nooutput
frames = STATS_blocks - 1

set terminal gif animate delay 40 loop 0 size 640,480 enhanced font "/System/Library/Fonts/Supplemental/Arial.ttf,12"
set output "ridge.gif"
set xrange [-1:1]
set yrange [-2.5:3.5]
set xtics 0.5
set ytics 1
set border 3
set tics nomirror
set key top left Left reverse

do for [i = 0:frames - 1] {
    set title sprintf("degree-9 polynomial, ridge = 10^{%g}%s", -9 + 0.5 * i, \
                      i < 6 ? ": overfits the noise" : i > 18 ? ": shrinks towards the mean" : \
                      i >= 10 && i <= 14 ? ": follows the signal" : "")
    plot "fits.dat" index i using 1:3 with lines lw 2 dt 2 lc rgb "#999999" title "sin(πx)", \
         "fits.dat" index i using 1:2 with lines lw 3 lc rgb "#ff0000" title "fit", \
         "samples.dat" using 1:2 with points pt 7 ps 1.2 lc rgb "black" title "15 noisy samples"
}
unset output
system("magick ridge.gif -coalesce \\( +clone -set delay 300 \\) +swap +delete -layers optimize ridge.gif")
