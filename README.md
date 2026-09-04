# logger — structured logging for slate

**A record is a value and a sink is a function of it.** What a record looks like is a rendering
somebody chooses, not something this package decided on the way out — so a terminal gets a line, a
collector gets a JSON object, and a test gets the record itself with nothing rendered at all.

```
slate add github.com/slate-language/logger
```

```slate
import { info, warn, setLevel, setSink, json } from logger

setLevel("warn")
setSink((r) -> print(json(r)))

info("below the level, and not written")
warn("slow", { ms: 1200, path: "/notes" })
```

```
{"time":"2026-09-03T18:19:05.985386Z","level":"warn","message":"slow","ms":1200,"path":"/notes"}
```

**Nothing here imports a host.** It is one file of ordinary slate, so the same package runs under the
interpreter, under node and in a browser.

## What there is

| | |
|---|---|
| `log(level, message, fields = {})` | the general form |
| `debug`, `info`, `warn`, `error` `(message, fields = {})` | that, with the level written in |
| `setLevel(level)` | the least severe level written; `"info"` to begin with |
| `setSink(fn)` | where a record goes — it is given the **record** |
| `setClock(fn)` | what stamps a record, answering the text that goes in `time` |
| `reset()` | the level, the sink and the clock back to what they started as |
| `text(record)` | one line for a person |
| `json(record)` | one JSON object for a collector |
| `writes(level)` | whether that level is written at the level now set |

A record is `{ time, level, message, ...fields }`, and `Record` is exported as a
[type](https://slatelang.dev). **The fields sit alongside the three that are always there** rather
than nested under a key: a collector indexes `path` and `ms` as themselves, and a record with its own
fields buried one level down is one every query has to reach into.

Each of the five writing functions answers the record it wrote, or `null` where the level held it
back.

## The three decisions

**A level this package does not know is a fault, not a silent drop.** A misspelled level in a call
that is only reached when something has already gone wrong is a message nobody would ever see.

**A field may not be called `time`, `level` or `message`.** Letting one through would mean a record
whose level is whatever the caller happened to pass, and the caller would never see it happen.

**The sink is given the record and picks a rendering itself**, which is why there are two rendering
functions and no `setFormat`. A sink that wants both — a line on the terminal and a JSON object down
a socket — writes both, and one that wants neither keeps the value.

## Sending it somewhere

The default sink is `print`, which is the one output every host has. A program writes its own in a
line, and the imports it needs are the program's and not this package's — which is the whole point of
a sink being a function:

```slate
import { setSink, json } from logger
import { send } from slate:net

setSink((r) -> send(collector, json(r) + "\n"))
```

**The two a server usually wants are one line each.** Down the error stream, so that what a program
says about its work stays out of what it produces:

```slate
import { setSink, text } from logger
import { stderr } from slate:process

setSink((r) -> stderr(text(r) + "\n"))
```

Or onto the end of a file, which is `O_APPEND` and not a read followed by a write, so a record is
never half a line and nothing already in the file is lost:

```slate
import { setSink, json } from logger
import { appendFile } from slate:fs

setSink((r) -> appendFile("app.log", json(r) + "\n"))
```

**The append is not awaited, and a sink answers nothing that could carry it** — the write goes onto
the loop and the line lands a moment later. That is what a log wants. A program that has to KNOW a
record reached the disk keeps the promise the sink made:

```slate
var landed = []

setSink((r) -> push(landed, appendFile("app.log", json(r) + "\n")))
```

Both sinks need slate 0.0.23.

## With `sluice`

[sluice](https://github.com/slate-language/sluice)'s `logger` guard hands a sink a record, so the two
fit together with nothing in between:

```slate
import { api, logger } from sluice
import { info } from logger

app.get("/notes", logger((r) -> info("request", r), handler))
```

## `setClock`

**A record's `time` comes from a clock the package holds, and `setClock` replaces it.** A test wants
one that does not move — a record's `time` is the one field nothing else can predict — and this
package's own suite is written that way.

## Running the suite

```
slate test tests
slate test --js tests
```

Both are green, and every line of the package is in them.

**It needs slate 0.0.22 or later** — and **0.0.25 under node or in a browser**, where the default
clock is `slate:time`'s instant. A program on an older JavaScript host supplies its own `setClock`.
