include pgxntool/base.mk

# TODO: Remove once this is pulled into pgxntool
installcheck: pgtap

-- TODO: Remove this after merging pgxntool 0.2.1+
testdeps: $(TEST_SQL_FILES) $(TEST_SOURCE_FILES)

B = sql

LT93		 = $(call test, $(MAJORVER), -lt, 93)

$B:
	@mkdir -p $@

installcheck: $B/cat_tools.sql
EXTRA_CLEAN += $B/cat_tools.sql
$B/cat_tools.sql: sql/cat_tools.in.sql Makefile pgxntool/safesed
	(echo @generated@ && cat $< && echo @generated@) | sed -e 's#@generated@#-- GENERATED FILE! DO NOT EDIT! See $<#' > $@
ifeq ($(LT93),yes)
	pgxntool/safesed $@ -e 's/, COLUMN/-- Requires 9.3: &/'
endif

