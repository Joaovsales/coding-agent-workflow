 Please perform a Context Sweep for the folder: <FOLDER_PATH>

  Rules:
  - Review the folder carefully and understand the architecture before moving files.
  - Identify files that are legacy, ad hoc, or unused in runtime.
  - Suggest a list of candidates to archive in `archive/<folder-name>/`.
  - Wait for my approval before moving anything.
  - Move approved files to the archive path.
  - Create/update `README.md` inside the target folder describing what remains and why.
  - Update `AGENTS.md` with a link to the folder README in the “Context Map” section.
  - Do not automate: reason about usage and references in code/docs.

  ———

  ## Manual Checklist (Agent-side)

  1. Inventory: list files and identify primary, runtime-relevant artifacts.
  2. Trace usage: search references in code/docs/tests.
  3. Classify: core vs legacy/ad hoc vs optional.
  4. Propose archive list: with reason per file.
  5. Wait for approval.
  6. Move to archive/<folder-name>/.
  7. Create README.md in folder: short, factual, and context-light.
  8. Update AGENTS.md: add a link in “Context Map”.
