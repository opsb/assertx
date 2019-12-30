.PHONY: test watch

test:
	mix test

watch-wip:
	find {lib,test} -name '*.ex*' | entr -c mix test --only wip /Users/opsb/Projects/bgl/open_banking/assertx/test/assertx_test.exs
