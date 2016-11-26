B = sql

include pgxntool/base.mk

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

