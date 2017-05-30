B = sql

testdeps: $(wildcard test/*.sql test/helpers/*.sql) # Be careful not to include directories in this

include pgxntool/base.mk

LT95		 = $(call test, $(MAJORVER), -lt, 95)
LT93		 = $(call test, $(MAJORVER), -lt, 93)

$B:
	@mkdir -p $@

versioned_in = $(wildcard sql/*--*--*.sql.in)
versioned_out = $(subst sql/,$B/,$(subst .sql.in,.sql,$(versioned_in)))

all: $B/cat_tools.sql $(versioned_out)
installcheck: $B/cat_tools.sql $(versioned_out)
EXTRA_CLEAN += $B/cat_tools.sql $(versioned_out)

# TODO: refactor the version stuff into a function
#
# This initially creates $@.tmp before moving it into place atomically. That's
# important to make the use of .PRECIOUS safe, which is necessary for
# watch-make not to freak out.
#
# Actually, that doesn't even fix it. TODO: Figure out why this breaks watch-make.
#
# Make sure not to insert blank lines here; everything needs to be part of the cat_tools.sql recipe!
#.PRECIOUS: $B/cat_tools.sql
$B/%.sql: sql/%.sql.in pgxntool/safesed
	(echo @generated@ && cat $< && echo @generated@) | sed -e 's#@generated@#-- GENERATED FILE! DO NOT EDIT! See $<#' > $@.tmp
ifeq ($(LT95),yes)
	pgxntool/safesed $@.tmp -E -e 's/(.*)-- SED: REQUIRES 9.5!/-- Requires 9.5: \1/'
else
	pgxntool/safesed $@.tmp -E -e 's/(.*)-- SED: PRIOR TO 9.5!/-- Not used prior to 9.5: \1/'
endif
ifeq ($(LT93),yes)
	pgxntool/safesed $@.tmp -E -e 's/(.*)-- SED: REQUIRES 9.3!/-- Requires 9.3: \1/'
else
	pgxntool/safesed $@.tmp -E -e 's/(.*)-- SED: PRIOR TO 9.3!/-- Not used prior to 9.3: \1/'
endif
	mv $@.tmp $@

