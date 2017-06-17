-- NOTE: To set this prior to 0.2.0 you need to hack the installed extension file to not create the cat_tools schema, or hack the current control file to not specify it!
CREATE EXTENSION cat_tools VERSION '0.2.0';
ALTER EXTENSION cat_tools UPDATE;

