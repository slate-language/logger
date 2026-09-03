// logger -- structured logging for slate, in one file and with no host in it.
//
// **A record is a value and a sink is a function of it**, which is the whole design. What a record
// looks like as text is a rendering somebody chooses, not something this package decided on the way
// out -- so a terminal gets a line, a collector gets a JSON object, and a test gets the record
// itself with nothing rendered at all.
//
//     import { info, setLevel, setSink, json } from logger
//
//     setLevel("warn")
//     setSink((r) -> print(json(r)))
//
//     info("this one is below the level and is not written")
//     warn("slow", { ms: 1200, path: "/notes" })
//
// **Nothing here imports a host.** The default sink is `print`, which is the one output every host
// has -- the interpreter, node and a browser alike. A server that wants stderr or a file writes
// three lines of its own; see the README.

import { now } from slate:time

// -- what a record is ------------------------------------------------------------------------------

// A log record. **`time`, `level` and `message` are always there and the fields are alongside them**,
// not nested under a key: a collector indexes `path` and `ms` as themselves, and a record with its
// own fields buried one level down is one every query has to reach into.
export type Record = { time: string, level: string, message: string }

// The levels, least to most severe. **An array and not a set of names**, because the whole of what a
// level means here is where it sits in this list.
val Levels = ["debug", "info", "warn", "error"]

// The default clock: the moment, as the text that goes in a record.
//
// **`slate:time` is imported here and nowhere else**, and it is the one thing in this file a host
// might not have. `setClock` is the way past it.
stamp() -> string = string(now())

// The default sink: a line of text on whatever this host calls its output.
written(record: Record)
    print(text(record))

// **The two defaults are declared ABOVE the `var`s that name them.** A top-level function is not
// hoisted past an initialiser -- `var sink = written` above its declaration is `written is not
// defined`.
var level = "info"
var sink = written
var clock = stamp

// -- the state -------------------------------------------------------------------------------------

// `setLevel(level)` -- the least severe level that is written. `"debug"` writes everything.
export setLevel(want: string)
    level = checked(want)

// `setSink(fn)` -- where a record goes. It is given the RECORD, and picks a rendering itself.
//
//     setSink((r) -> print(json(r)))
export setSink(fn: function)
    sink = fn

// `setClock(fn)` -- what stamps a record, answering the text that goes in `time`.
//
// **It exists for two reasons and both are real.** A test wants a clock that does not move, and a
// host may not have one at all -- `slate:time` is among the builtins the JavaScript back end still
// owes, so a program in a browser supplies its own until that lands.
export setClock(fn: function)
    clock = fn

// `reset()` -- the level, the sink and the clock back to what they started as.
export reset()
    level = "info"
    sink = written
    clock = stamp

// -- writing -----------------------------------------------------------------------------------------

// `log(level, message, fields)` -- the general form. The four named levels are this with the level
// written in.
//
// **A level this package does not know is a fault and not a silent drop.** A misspelled level in a
// call that is only reached when something has already gone wrong is a message nobody ever sees.
export log(want: string, message: string, fields: object = {}) -> object | null
    val at = checked(want)

    if !writes(at) then return null

    val record = made(at, message, fields)

    sink(record)

    record

// The four by name. Each answers the record it wrote, or `null` where the level held it back.
export debug(message: string, fields: object = {}) -> object | null = log("debug", message, fields)
export info(message: string, fields: object = {}) -> object | null = log("info", message, fields)
export warn(message: string, fields: object = {}) -> object | null = log("warn", message, fields)
export error(message: string, fields: object = {}) -> object | null = log("error", message, fields)

// Whether a level is written at the level now set.
export writes(want: string) -> boolean = indexOf(Levels, checked(want)) >= indexOf(Levels, level)

// A level, or a fault naming the ones there are.
checked(want: string) -> string
    if indexOf(Levels, want) == null
        throw "`" + want + "` is not a level -- they are " + join(Levels, ", ")

    want

// The record itself.
//
// **A field may not be called `time`, `level` or `message`.** Letting one through would mean a record
// whose level is whatever the caller happened to pass, and the caller would never see it happen.
made(at: string, message: string, fields: object) -> object
    var record = { time: clock(), level: at, message: message }

    for [k, v] in entries(fields)
        if k == "time" || k == "level" || k == "message"
            throw "`" + k + "` is part of every record, so it may not be a field as well"

        record[k] = v

    record

// -- the renderings ------------------------------------------------------------------------------------

// `text(record)` -- one line for a person reading a terminal.
//
//     2026-09-03T18:19:05Z WARN  slow ms=1200 path=/notes
//
// **A value with a space in it is quoted and a value with none is not**, which is what makes a line
// both readable and splittable. The level is padded so the messages line up.
export text(record: Record) -> string
    var out = record.time + " " + padded(upper(record.level)) + " " + record.message

    for [k, v] in entries(record)
        if k != "time" && k != "level" && k != "message"
            out = out + " " + k + "=" + quoted(string(v))

    out

// `json(record)` -- one JSON object for a collector, which is a record as it stands.
export json(record: Record) -> string = toJSON(record)

// A rendered value, quoted where reading it back would otherwise be guesswork.
quoted(v: string) -> string =
    if v == "" || contains(v, " ") || contains(v, "\"") then toJSON(v) else v

// The level, wide enough that every one of them is the same width.
padded(name: string) -> string
    var out = name

    while len(out) < 5
        out = out + " "

    out

