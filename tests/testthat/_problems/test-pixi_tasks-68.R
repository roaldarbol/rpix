# Extracted from test-pixi_tasks.R:68

# prequel ----------------------------------------------------------------------
task_list_json <- '[
  {
    "environment": "default",
    "tasks": [],
    "features": [
      {"name": "default", "tasks": [
        {"name": "test", "cmd": "Rscript -e \'devtools::test()\'",
         "description": "Run the tests", "depends_on": [], "args": null},
        {"name": "render", "cmd": ["quarto", "render", "{{ file }}"],
         "description": null,
         "depends_on": [{"task_name": "test", "args": null, "environment": null}],
         "args": [{"name": "file", "default": null, "choices": null}]}
      ]}
    ]
  },
  {
    "environment": "r44",
    "tasks": [{"name": "inline", "cmd": null, "description": null,
               "depends_on": [{"task_name": "test"}], "args": null}],
    "features": [
      {"name": "r44", "tasks": [
        {"name": "check", "cmd": "R CMD check", "description": null,
         "depends_on": [], "args": null}
      ]},
      {"name": "default", "tasks": [
        {"name": "test", "cmd": "Rscript -e \'devtools::test()\'",
         "description": "Run the tests", "depends_on": [], "args": null},
        {"name": "render", "cmd": ["quarto", "render", "{{ file }}"],
         "description": null,
         "depends_on": [{"task_name": "test", "args": null, "environment": null}],
         "args": [{"name": "file", "default": null, "choices": null}]}
      ]}
    ]
  }
]'

# test -------------------------------------------------------------------------
local_recorded_pixi(list(
    stdout = '[{"environment": "default", "tasks": [], "features": []}]'
  ))
