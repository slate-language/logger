// The whole package, from the outside.
//
// **Every test here sets a clock that does not move**, which is what a log suite wants anyway: a
// record's `time` is the one field nothing else can predict. It is also what makes this suite run
// under `slate test --js`, `slate:time` being one of the things the JavaScript back end still owes.

import { log, debug, info, warn, error, setLevel, setSink, setClock, writes, text, json, reset, Record } from "../logger.sl"

val Stamp = "2026-09-03T18:19:05Z"

// A sink that keeps what it was given, and the package put back the way it was found.
watching() -> array
    var seen = []

    reset()
    setClock(() -> Stamp)
    setSink((r) -> push(seen, r))

    seen

@test
A_RECORD_IS_A_VALUE_WITH_ITS_FIELDS_ALONGSIDE_THE_THREE_THAT_ARE_ALWAYS_THERE()
    // Not nested under a key: a collector indexes `path` and `ms` as themselves.
    val seen = watching()

    info("request", { method: "GET", path: "/notes", ms: 3 })

    assertEq(seen[0], { time: Stamp, level: "info", message: "request", method: "GET", path: "/notes", ms: 3 })
    assert(seen[0] is Record)

    reset()

@test
THE_SINK_IS_GIVEN_THE_RECORD_AND_PICKS_A_RENDERING_ITSELF()
    val seen = watching()

    warn("slow", { ms: 1200 })

    assert(seen[0] is object, "a record and not a line of text")
    assertEq(text(seen[0]), Stamp + " WARN  slow ms=1200")
    assertEq(json(seen[0]), "{\"time\":\"" + Stamp + "\",\"level\":\"warn\",\"message\":\"slow\",\"ms\":1200}")

    reset()

@test
log_IS_THE_GENERAL_FORM_AND_THE_FOUR_NAMES_ARE_IT_WITH_THE_LEVEL_WRITTEN_IN()
    val seen = watching()

    setLevel("debug")

    log("warn", "by name", { n: 1 })
    warn("by name", { n: 1 })

    assertEq(seen[0], seen[1])

    reset()

@test
A_LEVEL_BELOW_THE_ONE_SET_IS_NOT_WRITTEN_AND_ANSWERS_null()
    val seen = watching()

    setLevel("warn")

    assertEq(debug("held"), null)
    assertEq(info("held"), null)
    assert(warn("written") != null)
    assert(error("written") != null)

    assertEq(len(seen), 2)
    assertEq([seen[0].level, seen[1].level], ["warn", "error"])

    reset()

@test
debug_IS_THE_LEVEL_THAT_WRITES_EVERYTHING_AND_info_IS_THE_DEFAULT()
    val seen = watching()

    assertEq(debug("held at the default"), null)

    setLevel("debug")

    assert(debug("written now") != null)
    assertEq(len(seen), 1)

    reset()

    assertEq(writes("info"), true)
    assertEq(writes("debug"), false)

@test
AN_UNKNOWN_LEVEL_IS_REFUSED_WHEREVER_IT_IS_WRITTEN()
    // A misspelled level in a call that is only reached when something has already gone wrong is a
    // message nobody would ever see.
    var said = null

    setLevel("trace") catch e ->
        said = e.message

    assertEq(said, "`trace` is not a level -- they are debug, info, warn, error")

    log("TRACE", "shouting does not help") catch e ->
        said = e.message

    assertEq(said, "`TRACE` is not a level -- they are debug, info, warn, error")

    writes("verbose") catch e ->
        said = e.message

    assertEq(said, "`verbose` is not a level -- they are debug, info, warn, error")

    reset()

@test
A_FIELD_MAY_NOT_BE_ONE_OF_THE_THREE_A_RECORD_ALREADY_HAS()
    // Letting one through would mean a record whose level is whatever the caller happened to pass.
    var said = null

    watching()

    info("request", { level: "error" }) catch e ->
        said = e.message

    assertEq(said, "`level` is part of every record, so it may not be a field as well")

    info("request", { time: "yesterday" }) catch e ->
        said = e.message

    assertEq(said, "`time` is part of every record, so it may not be a field as well")

    reset()

@test
text_QUOTES_A_VALUE_THAT_WOULD_OTHERWISE_BE_GUESSWORK_TO_READ_BACK()
    val seen = watching()

    info("done", { note: "a long one", empty: "", n: 3, ok: true })

    assertEq(text(seen[0]), Stamp + " INFO  done note=\"a long one\" empty=\"\" n=3 ok=true")

    reset()

@test
THE_LEVEL_IS_PADDED_SO_THAT_THE_MESSAGES_LINE_UP()
    val seen = watching()

    setLevel("debug")

    debug("a")
    error("b")

    assertEq(text(seen[0]), Stamp + " DEBUG a")
    assertEq(text(seen[1]), Stamp + " ERROR b")

    reset()

@test
json_IS_THE_RECORD_AS_IT_STANDS_AND_KEEPS_THE_ORDER_IT_WAS_BUILT_IN()
    val seen = watching()

    info("request", { path: "/notes", ms: 3 })

    assertEq(json(seen[0]),
        "{\"time\":\"" + Stamp + "\",\"level\":\"info\",\"message\":\"request\",\"path\":\"/notes\",\"ms\":3}")

    reset()

@test
reset_PUTS_THE_LEVEL_THE_SINK_AND_THE_CLOCK_BACK()
    val seen = watching()

    setLevel("error")
    info("held")

    reset()

    assertEq(writes("info"), true)
    assertEq(len(seen), 0, "and the sink is no longer the one this test installed")
