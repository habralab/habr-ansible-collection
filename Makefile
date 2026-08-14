ROLES_WITH_TESTS := $(patsubst roles/%/Makefile,%,$(wildcard roles/*/Makefile))

.PHONY: test lint $(addprefix test-,$(ROLES_WITH_TESTS))

test: $(addprefix test-,$(ROLES_WITH_TESTS))

define role-test-target
test-$(1):
	$(MAKE) -C roles/$(1) test
endef

$(foreach role,$(ROLES_WITH_TESTS),$(eval $(call role-test-target,$(role))))

lint:
	tox
