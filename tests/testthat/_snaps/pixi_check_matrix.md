# pixi_check_matrix() runs in each environment, one at a time

    Code
      matrix <- pixi_check_matrix()
    Message
      i Running in "r44".
      i Running in "r45".

---

    Code
      matrix
    Output
      -- Tests -----------------------------------------------------------------------
      v r44  R 4.4.3: 3 passed, 0 failed, 1 skipped, 0 warnings (2 s)
      x r45  failed (2 s)
      See what failed with `cat(x$output[[i]])`, for row `i`.

# pixi_check_matrix() can run everywhere at once, after installing

    Code
      matrix <- pixi_check_matrix(c("r44", "r45"), what = "check", parallel = TRUE)
    Message
      i Running in 2 environments at once.

---

    Code
      matrix
    Output
      -- R CMD check -----------------------------------------------------------------
      v r44  R 4.4.3: 0 errors, 0 warnings, 1 note (2 s)
      v r45  R 4.4.3: 0 errors, 0 warnings, 1 note (2 s)

# pixi_check_matrix() can run a task

    Code
      matrix <- pixi_check_matrix("r44", task = "lint")
    Message
      i Running in "r44".

---

    Code
      matrix
    Output
      -- Task ------------------------------------------------------------------------
      v r44  passed (1.2 min)

# finish_run() reads a task's exit status and output

    Code
      result <- finish_run(local_job("cat('done'); q(status = 1)"))
    Message
      x "r44" failed (time).

# use_pixi_check_matrix() adds an environment per version of R

    Code
      names <- use_pixi_check_matrix(c("4.4", "4.5"))
    Message
      v Added the environments "r44" and "r45". Run `pixi_check_matrix()`.

