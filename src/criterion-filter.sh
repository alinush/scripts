cat "$1" \
    | grep -v Benchmarking \
    | grep -v Found \
    | grep -v Warning \
    | grep -v mild \
    | grep -v severe \
    | grep -v Running \
    | grep -v '%' \
    | grep -v 'change:' \
    | grep -v "^WARNING:" \
    | grep -v "Performance has regressed." \
    | grep -v "Change within noise threshold." \
    | grep -v "No change in performance detected." \
    | grep -v "Performance has improved."
