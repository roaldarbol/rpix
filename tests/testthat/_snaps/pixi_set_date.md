# exclude_newer_value() takes dates, timestamps and durations

    Code
      exclude_newer_value("last summer")
    Condition
      Error:
      ! `date` must be a date, a timestamp or a duration.
      i For example "2025-06-01", "2025-06-01T12:00:00Z" or "7d".

# pixi_set_date() sets the date and updates pixi.lock

    Code
      previous <- pixi_set_date("2025-06-01", path = calls$dir)
    Message
      v Set `exclude-newer = "2025-06-01"` in 'pixi.toml'.

---

    Code
      previous <- pixi_set_date(NULL, path = calls$dir)
    Message
      v Removed the date from 'pixi.toml'. Get newer packages with `pixi_update()`.

# pixi_set_date() puts pixi.toml back if Pixi can't solve it

    Code
      pixi_set_date("2020-01-01", path = calls$dir)
    Message
      v Set `exclude-newer = "2020-01-01"` in 'pixi.toml'.
    Condition
      Error:
      ! Pixi couldn't solve the project with packages as of "2020-01-01", so 'pixi.toml' is as it was.
      i The project may pin versions newer than that, e.g. ones `pixi_add()` added. See Pixi's output above.
      i Setting the date when you create a project, with `use_pixi(date = "2020-01-01")`, avoids that.
      Caused by error in `run_pixi()`:
      ! no solution

