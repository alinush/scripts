test_failed() {
    echo "ERROR: $1"
    exit 1
}

tests_succeeded() {
    echo "All tests succeeded!"
    exit 0
}
