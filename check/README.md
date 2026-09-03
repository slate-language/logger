# The hand-run check

```
slate check/clock.sl
```

**It must print two lines** — an `INFO` and a `WARN`, stamped with the moment it ran:

```
2026-09-03T18:22:46.470047Z INFO  the default sink writes a line of text
2026-09-03T18:22:46.470091Z WARN  and the default clock stamps it at="this moment"
```

It is here rather than under `tests/` for one reason: **it is the only thing in this package that
needs `slate:time`**, and `slate:time` is among the builtins the JavaScript back end still owes. The
suite sets a clock of its own — which a log suite wants anyway, a record's `time` being the one field
nothing else can predict — and therefore runs green under `slate test tests` **and**
`slate test --js tests`. That is what the browser claim rests on, and a test of the default clock
sitting beside it would have taken the node half of it away.

When the JavaScript back end grows an instant, this can move into the suite.
