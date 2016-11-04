include pgxntool/base.mk

# TODO: Remove once this is pulled into pgxntool
installcheck: pgtap

B = sql

LT95		 = $(call test, $(MAJORVER), -lt, 95)

$B:
	@mkdir -p $@

installcheck: $B/cat_tools.sql
EXTRA_CLEAN += $B/cat_tools.sql
$B/cat_tools.sql: sql/cat_tools.in.sql Makefile
ifeq ($(LT95),yes)
	cat $< | sed -e 's/, COLUMN/-- Requires 9.3: &/' > $@
else
	cp $< $@
endif

