# Constitution 

<!--

Current version: 1.0.0

-->

This is  an immutable constitution.
GEMINI.md / AGENTS.md must poblige to these bullet points at ANY GIVEN TIME.
the only changes we can do to this constitution need to be agreed by 2/3 of people (Riccardo, Emiliano and AI).
this needs to be documented in a PR linked to a GHI where 2 of them has spoken.

The idea is that this constituion provides meta-steps which AGENTS.md need to obey to.

## Principles

1. This app is a modern blueprint for Rails (8) developers on GCP.
2. A workshop for this app MUST be present, either in workshop/ or in a public Google repository which will contain that content. (Ideally, we're migrating from the first to the second one as a migration path).
3. The workshop will have N step. For every workshop step, we'll have a branch with a deterministic name (eeg workshop/step1..).
4. Since the workshop contains a number of "versions" of the same app (since students/practitioneers have been requested to take an initial version and then change the code for a number of steps.
,
we agree that MAIN will try as much as possiblt to converge with the FINAL versioon of the workshop (where the Database on cloud SQL works, the connection to GCS works, and so on).
6. The workshop shld be able to work in localhost at ANY GIVEN TIME. Tests with decent timeouts  (<5sec) willl give a meaningful mesage to user if DB is not reachable, GCS is not configured and so on. Ideally the student should be able at any given time to know whats working and whats missing so they can (alone or guided by AI) .
