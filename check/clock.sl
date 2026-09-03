// The default clock and the default sink, which are the two lines the suite does not exercise.
//
// **Run by hand — see `check/README.md`.** It needs `slate:time`, so it works under the interpreter
// and faults under `slate --js` until the JavaScript back end has an instant.

import { info, warn, setLevel } from "../logger.sl"

setLevel("debug")

info("the default sink writes a line of text")
warn("and the default clock stamps it", { at: "this moment" })
