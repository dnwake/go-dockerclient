RUN_TEST := $(SCRIPTDIR)/client_test.sh

tests: | test_bad test_good test_error

test_bad: export TRUST=false
test_bad: export CORRUPT_IMAGE=true
test_bad: export EXPECTED_OUTPUT=I AM BAD
test_bad: prepare_tests
	echo ""
	echo ""
	echo "==================================================================="
	echo "Pulling corrupted image without content trust; should get bad image"
	echo "==================================================================="
	echo ""
	$(RUN_TEST)

test_good: export TRUST=true
test_good: export CORRUPT_IMAGE=fals
test_good: export EXPECTED_OUTPUT=I AM GOOD
test_good: prepare_tests
	echo ""
	echo ""
	echo "============================================================"
	echo "Pulling good image with content trust; should get good image"
	echo "============================================================"
	echo ""
	$(RUN_TEST)

### Should throw error
test_error: export TRUST=true
test_error: export CORRUPT_IMAGE=true
test_error: export EXPECTED_RESULT=fail
test_error: prepare_tests
	echo ""
	echo ""
	echo "===================================================================="
	echo "Pulling corrupted image with content trust; should get error message"
	echo "===================================================================="
	echo ""
	$(RUN_TEST) && echo "(Error message was expected)"

prepare_tests: prepare_client client push_images
