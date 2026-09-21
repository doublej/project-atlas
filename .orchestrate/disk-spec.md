# disk — Specification

Implemented as `atlas disk` (atlas-cli/src/disk/) + `atlas-disk` (the terminal screen).
Ported from `~/dev/_management/disk` (bash scripts + disk-tui), which this spec was abstracted from.

## What it is
A personal disk-space manager for one developer's Mac. It frees space in three ways.
First, it moves development projects nobody has worked on in months into one archive file
each, and brings them back on request. Second, it finds folders of downloaded or generated
files and deletes the ones the user approves, after telling them what each one is and how
to get it back. Third, it trims unused entries from developer-tool caches. A project is
never removed until a verified copy of it exists. Nothing else is deleted without the
user's approval, given either each time or once as a standing rule (see **Approval policy**).

## Who uses it
One user, the owner of the Mac, from a terminal. Scripts and AI agents also run it
on the user's behalf. Some jobs also run on a schedule with nobody watching.

## What a user can do

### Understand where the space is
- **Analyze the project folder** — the user runs an analysis of their development folder →
  sees every project with its size, its age, and its state. A project is **active** if it
  was edited in the last 30 days, **inactive** if not, and **archive-eligible** if it is
  both 180 days or older and 100 MB or larger. Only projects two levels deep
  (`<category>/<project>`) count. Personal, management, scratch and already-archived
  categories are skipped.
- **Limit the analysis by size** — the user sets a minimum size → smaller projects are left out.
- **See why a project has its age** — a project's age is the time since its newest file that
  counts as an edit. Dependencies, build output, lock files, version-control history and
  tool folders never count as edits. The user can see which file set the age and, next to
  it, the date of the last commit. A project with no files that count as edits is never
  archive-eligible.
- **See uncommitted and unpushed work** — projects with uncommitted changes, or with commits
  that were never pushed, are flagged wherever projects are listed. When the push state
  cannot be established (no remote, remote unreachable), it is shown as **unknown**.
- **See how old a result is** — every list shows when its analysis or scan ran. Results
  survive a restart and can be listed again without scanning.
- **Change the thresholds** — the user sets the active window, the archive age, the archive
  size, and the skipped categories once, and every command and screen uses them.

### Archive projects
- **Archive all eligible projects** — the user asks for every archive-eligible project →
  sees the plan (each project, its size, where it goes, the expected space freed) and
  confirms. Each project is then archived, biggest first.
- **Archive specific projects** — the user names one or more projects by
  `<category>/<project>` → only those are archived, whatever their age or size, after the
  same plan and confirmation.
- **Run unattended** — the user adds the unattended flag → the plan runs without asking, but
  only for items the approval policy allows without a prompt. The rest are refused, and
  each refused item is reported with the approval it needs.
- **Preview only** — the user asks for the plan without running it.
- **Keep rebuildable folders in the archive** — by default, dependency folders, build output
  and caches are left out of the archive. The user can ask for an exact copy instead.
- **Archive a project with uncommitted or unpushed work** — this needs its own
  confirmation for that project. Unattended, it also needs a separate explicit flag.
  Without that flag, the project is refused.
- **Set compression** — archives use fast compression by default. The user can turn it off
  or choose a stronger setting.
- **See what an archive run did** — for each project the user sees its size before, the
  archive's size, and the measured change in free disk space. Space still used by an archive
  file on this Mac is reported separately from space already moved to the cloud.
- **Choose the archive location** — iCloud Drive by default. The user can point it at
  another folder, such as a network share or an external drive.

### Look inside archives
- **List archives** — the user sees every archive version with its version identifier
  (archive date and time), its size, whether it is **verified**, and its storage state:
  **local only**, **uploading**, **uploaded**, **cloud only**, **unknown**, or **not
  applicable** (for locations with no cloud).
- **See what an archive holds** — the user sees an archive's file list and what was left out,
  without unpacking it.
- **Check an archive** — the user asks for a check → learns whether the archive still
  matches the record of its contents that was saved when it was made.
- **Delete old archive versions** — the user removes versions they no longer need, one at a
  time or by keeping the newest N. Automatic removal is off by default. When it is on, it
  never removes the only version of a project.

### Restore projects
- **Restore a project** — the user names a project → its newest archive version is
  unpacked back to its original place. If the archive is only in the cloud, it is
  downloaded first with visible progress. The archive file is then deleted.
- **Restore a specific version** — the user picks a version by its identifier.
- **Restore several projects at once** — more than one project in one command. Selecting
  two versions of the same project in one restore is refused.
- **Restore but keep the archive** — the archive file stays after unpacking.

### Clean up rebuildable folders
- **Scan the home folder** — the user runs a scan → sees rebuildable folders largest first,
  with a total that never counts a folder twice when one sits inside another. iCloud Drive,
  other cloud storage, device backups, Photos, Music and Movies are never scanned.
- **See the risk of each folder** — every folder has one of three risk levels:
  **rebuildable** (build output and caches, recreated automatically), **reinstallable**
  (dependencies and environments, need a download and some time), or **review** (simulators,
  container disk images, toolchains, system caches, which may hold state that exists nowhere
  else). Each folder also shows why it matched, how to get it back, and whether something
  seems to be using it right now.
- **Filter by risk** — the user limits the list or a cleanup to one risk level.
- **Pick folders to delete** — the user marks one or many (with select all and deselect all),
  sees each folder's contents and its newest files, then sees the count, the total and the
  paths, and confirms.
- **Clean the lowest risk level unattended** — the user turns on a standing rule that allows
  rebuildable-level cleanup without confirmation.
- **Choose Trash or permanent delete** — review-level folders go to the macOS Trash by default,
  and the user can choose permanent deletion instead. Rebuildable and reinstallable folders
  are deleted permanently. The result shows that space moved to the Trash is not freed until
  the Trash is emptied.
- **Set a minimum size** for the scan. Default: 100 MB.

### Trim tool caches
- **Trim now** — the user runs a trim → each installed developer tool (Python packages,
  Homebrew, npm, bun, Rust packages, iOS simulators) removes only the entries it no longer
  uses, using that tool's own clean-up operation. Tools that are not installed are skipped.
- **Sweep old Rust build output** — a separate step, off by default. It removes build output
  unused for 30 days from up to 50 projects.
- **Preview a trim** — lists the steps without running them.
- **See what a trim freed** — the size of each main cache before and after.

### Scheduled jobs
- **Get told when space builds up** — every week a scan runs. If the reclaimable total
  reaches 50 GB, or grew by more than 10 GB since the last scan, a macOS notification shows
  the total and the three biggest folders. The notification has a **Review** button that
  opens the cleanup list. Both limits can be changed.
- **Trim caches weekly** — every week the cache trim runs unattended. It includes the Rust
  sweep only if the user turned it on.
- **Turn schedules on and off** — the user enables, disables, or changes the time of each
  schedule with one command.
- **See schedule status** — the user sees each schedule's state, next run, last run and its
  result.
- **Check the setup** — a diagnostic command reports what is wrong: a schedule that is not
  installed, points at the wrong place, or last failed, an archive location that is
  unreachable, a missing tool, or an interrupted operation.

### Use the terminal screen
- **Open the screen** — archive-eligible projects on the left, archive versions on the
  right with their storage state, a log pane, and free disk space and result age in
  the header.
- **Move and mark** — arrow keys move, Tab switches columns, space marks. Totals of the
  marked items are shown.
- **Search** — `/` filters the focused column.
- **Archive marked projects** — `a`, shows the plan, `y` confirms.
- **Restore marked archives** — `r`, shows the plan, `y` confirms.
- **Rescan** — `R` runs a new analysis and shows its finish time.
- **Watch progress** — a running job shows progress and streams its output to the log pane.
  Failures, successes and skips each have their own colour.
- **Cancel a job** — the user cancels a running job. It stops at the next safe point.
  Anything it did not finish is reported and can be recovered (see **Recover an
  interrupted operation**).
- **Quit** — `q` quits. If a job is running, the user is asked whether to cancel it or let
  it finish in the background.
- **Switch colour theme** — `t` cycles the themes. Auto follows the terminal.

### Use the web console
- **Open the Disk page** — `/disk` in the atlas web console (`http://localhost:47891/disk`).
  Tabs: Projects, Archives, Cleanup, Trim, Schedules, Log, Settings. The header shows free
  space, the age of the analysis and the scan, and what `doctor` found.
- **Same operations, same rules** — the page runs `atlas disk` for everything. Reads wait for
  `--json`; changes run as a job whose output the page follows, with its own colours for
  done, skipped, refused and failed. Cancel stops the job at its next safe point.
- **Confirm in the page** — before a change the page shows the plan from a dry run (for
  cleanup: each folder's contents and newest files). Saying yes runs the change with
  `--confirmed`. A dirty or unpushed project needs its own tick (`--confirm-dirty`).
  Whatever the approval policy refuses is still refused.
- **Only from this Mac** — the page reads from anywhere the console is reachable, but changes
  are refused (403) when the request came through the NAS proxy or another origin.
- **The weekly warning opens it** — the notification's Review button opens the Cleanup tab.

### Automate it
- **Machine-readable output** — every command can return its result in a structured form,
  for scripts and agents.
- **Predictable exit results** — success, nothing to do, partly failed, and refused (a
  safety check failed or an approval was missing) each give a different exit result.
- **Same operations everywhere** — everything the screen or the web console can do, a command can also do.

### Review and recover
- **Read the operation log** — the user sees every archive, restore, deletion, trim and
  manual cleanup step: when, who (user, schedule, or an agent), what, where to, size,
  result. Each run has its own identifier, so one run's steps can be read together.
- **Recover an interrupted operation** — when an operation was interrupted, for example by a
  crash, a power loss or a cancelled job, the next run shows it. The user can then finish
  it or undo it. For example, a project whose removal was interrupted is removed, or
  restored from its verified archive.
- **Log manual cleanup steps** — whoever is cleaning by hand, the user or an agent, can
  record their own steps in the same log: move a file to the macOS Trash (Put Back still
  works), move a file without overwriting, run a command, record a skip with a reason, or
  add a note.

## Approval policy

| Operation | Interactive | Unattended flag | Scheduled |
|---|---|---|---|
| Archive a project | confirm plan | allowed | never |
| Archive a project with uncommitted or unpushed work | confirm for that project | refused unless its own flag is given | never |
| Restore a project | confirm plan | allowed | never |
| Delete archive versions | confirm | refused unless the keep-newest-N rule is on | keep-newest-N rule only, if on |
| Delete rebuildable folders | confirm | only with the standing rule | never |
| Delete reinstallable folders | confirm | refused | never |
| Delete review folders | confirm | refused | never |
| Delete unclassified folders | never offered | refused | never |
| Trim tool caches | confirm plan | allowed | allowed |
| Sweep old Rust build output | confirm plan | allowed if turned on | allowed if turned on |

When an approval is missing, an unattended or scheduled run never asks. It refuses that
item, reports why, and continues with the rest.

## What the system remembers
- The latest analysis and scan with their time and settings, until the next ones.
- The user's thresholds, standing rules, archive location, compression setting, schedule
  settings and theme.
- Archived projects, one file per archive run, each with a record of its contents made when
  it was written. They stay until restored or deleted.
- The operation log, kept permanently, including operations that started but did not finish.
  Schedule run logs are kept for 30 days.

## What it connects to
- **iCloud Drive** (default archive location) — archives upload in the background. Once an
  archive is uploaded, its local copy can be removed to free space. On restore, an archive
  that is only in the cloud is downloaded first.
- **macOS notifications** — the space warning, with a Review button.
- **macOS Trash** — where review-level folders and manual cleanup steps send files by default.
- **The user's installed developer tools** — the cache trim asks each one to trim itself.
- **Version control** — read-only, to flag uncommitted or unpushed work and show commit age.

## Rules that always hold

### Archiving and restoring
- **Verified means complete:** an archive is verified when every file it should contain is
  present, and its size and content fingerprint match the project as it was read.
- **Removal only after verification:** a project is removed only after its archive is
  complete, saved under its final name, and verified. If any step fails, the project stays
  as it was, and any partial archive is removed.
- **Changes during archiving:** if any file in the project changes while it is being
  archived, the project is not removed. Its archive is kept but marked as not verified.
- **Restoring:** a restore unpacks to a temporary place first and moves the project into
  place only when it is complete. It never overwrites a folder that already exists.
- **No overwrites:** an archive never overwrites another archive. Each version has its own
  identifier.
- **Room first:** archiving checks there is enough room at the archive location and on this
  Mac before it starts. If there is not, the project is skipped and the reason is logged.

### Cleanup
- **A parent is as risky as its contents:** a folder's risk level is the highest level of
  anything inside it. A folder that contains another project or files that don't belong
  to its type is review-level.
- **Stay inside the folder:** deletion stays inside the chosen folder. Links are never
  followed, and a link is removed as a link.
- **Check again before deleting:** just before deletion, each folder is checked again. If
  its size, its newest file, or its contents list differs from the scan, it is skipped
  and reported.
- **Folders in use:** a folder that something seems to be using is flagged in interactive
  cleanup and skipped in unattended cleanup.
- **No double counting:** a cleanup never counts a folder twice when one sits inside
  another.

### Tool trims
- **Tools clean themselves:** scheduled trims only use each tool's own clean-up operation
  and never delete whole caches. The Rust sweep is the only exception, and it runs only if
  turned on.
- **Timeouts:** a step that runs longer than 3 minutes (the limit can be changed) is
  stopped, and the run continues only after it has stopped. The report says the step timed
  out and what it had already changed, if that can be known.

### Every run
- **One job at a time:** only one job that changes files runs at a time. A second one is
  refused and told why.
- **Batches continue:** one failed item never stops a batch. Each item is reported as done,
  skipped, refused or failed.
- **Log first:** every change to files writes a start record to the operation log before it
  begins and a result record after. If the start record cannot be written, the change does
  not start.
- **Recovery:** a start record with no result means the operation was interrupted. The next
  run reports it and offers recovery. Until the user chooses finish or undo, no other job
  touches that item.

## Qualities
- Interrupting any job, whether by cancel, crash or power loss, never loses a project. At
  every moment either the project or its verified archive exists, and the interrupted
  operation can be finished or undone.
- Only for this Mac. It depends on macOS.

## Not in scope
- Backing up the NAS or anything outside the development folder.
- Archiving on a schedule. Archiving always starts with a user or an agent acting for them.
- Archiving projects deeper than two levels, or in the skipped categories.
- Whole-cache deletion, container cleanup, and toolchain uninstalls in scheduled jobs.
- Unsaved changes in open editors. Only work that version control can see is flagged.
