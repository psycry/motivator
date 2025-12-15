from pathlib import Path

path = Path(r"C:\Users\wjlan\Projects\motivator\lib\main.dart")
text = path.read_text()
needle = "trackedDuration: _currentTrackedDuration(task),\n"
replacement = "trackedDuration: _currentTrackedDuration(task),\n                            lateTrackedDuration: task.lateTrackedDuration,\n"
if needle not in text:
    raise SystemExit("expected snippet not found")
text = text.replace(needle, replacement)
path.write_text(text)
