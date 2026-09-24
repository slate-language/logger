{
    name: "logger",
    version: "0.2.1",

    // One file, so one door. **There is nothing here a host has to provide** beyond `print` and, for
    // the default clock, `slate:time` -- which is what lets the same package run under the
    // interpreter, under node and in a browser.
    main: "logger.sl",
}
