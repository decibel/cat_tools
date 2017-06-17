/*
 * Now load our extension. We don't use IF NOT EXISTs here because we want an
 * error if the extension is already loaded (because we want to ensure we're
 * getting the very latest version).
 */
CREATE EXTENSION cat_tools;
