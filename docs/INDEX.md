<documentation>
  <header>rsparrow Documentation Index</header>

  <description>Navigation hub for all project documentation. Documents are grouped by purpose.</description>

  <section>
    <title>Plans — Execution Roadmap</title>
    <subtitle>Sequential refactoring plans for CRAN preparation.</subtitle>
    <entries>
      <file>
        <path>plans/CRAN_ROADMAP.md</path>
        <description>Full CRAN preparation checklist with priority tiers</description>
      </file>
      <file>
        <path>plans/PLAN_01_PACKAGE_STRUCTURE.md</path>
        <description>Package rename, Fortran cleanup, license, .Rbuildignore</description>
      </file>
      <file>
        <path>plans/PLAN_02_NONCORE_SEPARATION.md</path>
        <description>Shiny/GUI separation, legacy file deletion, Imports reduction</description>
      </file>
      <file>
        <path>plans/PLAN_03_API_DESIGN.md</path>
        <description>Exported API skeleton, NAMESPACE, Suggests/Imports split</description>
      </file>
      <file>
        <path>plans/PLAN_04A_WINDOWS_GLOBALENV_CORE.md</path>
        <description>Windows-only code removal, startModelRun.R GlobalEnv refactor</description>
      </file>
      <file>
        <path>plans/PLAN_04B_GLOBALENV_REMAINING_SPECSTRINGS.md</path>
        <description>Remaining assign(.GlobalEnv) elimination, spec-string inlining</description>
      </file>
      <file>
        <path>plans/PLAN_04C_UNPACKLIST_REMOVAL.md</path>
        <description>unPackList() elimination + eval(parse()) cleanup (COMPLETE)</description>
      </file>
      <file>
        <path>plans/PLAN_04D_API_IMPLEMENTATION.md</path>
        <description>Implement exported skeleton functions (all 4 sub-sessions COMPLETE)</description>
      </file>
      <file>
        <path>plans/PLAN_04D_1_S3_METHODS.md</path>
        <description>Sub-session 1 of 4 — S3 method bodies (COMPLETE)</description>
      </file>
      <file>
        <path>plans/PLAN_04D_2_READ_DATA.md</path>
        <description>Sub-session 2 of 4 — read_sparrow_data() implementation (COMPLETE)</description>
      </file>
      <file>
        <path>plans/PLAN_04D_3_MODEL_ENTRY_POINT.md</path>
        <description>Sub-session 3 of 4 — rsparrow_model() main estimation entry point (COMPLETE)</description>
      </file>
      <file>
        <path>plans/PLAN_04D_4_PREDICT_WRAPPERS.md</path>
        <description>Sub-session 4 of 4 — predict.rsparrow, rsparrow_bootstrap/scenario/validate (COMPLETE)</description>
      </file>
      <file>
        <path>plans/PLAN_05A_DEAD_CODE_REMOVAL.md</path>
        <description>Dead-code removal: 15 REMOVE-list files deleted, callers inlined (COMPLETE)</description>
      </file>
      <file>
        <path>plans/PLAN_05B_PREDICT_CONSOLIDATION.md</path>
        <description>Predict consolidation: predict_core.R kernel, estimateFeval merge, 18 eval/parse eliminated (COMPLETE)</description>
      </file>
      <file>
        <path>plans/PLAN_05C_EVAL_PARSE_CLEANUP.md</path>
        <description>Remaining eval(parse()) cleanup: 4panel plotly, applyUserModify API redesign, scenario prep (COMPLETE)</description>
      </file>
      <file>
        <path>plans/PLAN_05D_DIAGNOSTIC_PLOT_INFRASTRUCTURE.md</path>
        <description>Delete 20 diagnostic/report files; implement plot.rsparrow(type=) dispatch (COMPLETE)</description>
      </file>
      <file>
        <path>plans/PLAN_04_STATE_ELIMINATION.md</path>
        <description>Former working title for Plan 04A (historical)</description>
      </file>
    </entries>
  </section>

  <section>
    <title>Reference — Stable Technical Documentation</title>
    <entries>
      <file>
        <path>reference/ARCHITECTURE.md</path>
        <description>Module structure, execution flow, and component relationships</description>
      </file>
      <file>
        <path>reference/DATA_STRUCTURES.md</path>
        <description>Key data objects, CSV control file formats, Fortran interfaces</description>
      </file>
      <file>
        <path>reference/FUNCTION_INVENTORY.md</path>
        <description>All functions classified KEEP/REFACTOR/MERGE/REMOVE (post-Plan 05D: 118 R files; 20 REMOVE-list files deleted)</description>
      </file>
      <file>
        <path>reference/SPARROW_METHODOLOGY.md</path>
        <description>Scientific background on SPARROW watershed modeling</description>
      </file>
      <file>
        <path>reference/TECHNICAL_DEBT.md</path>
        <description>Prioritized catalog of remaining code issues</description>
      </file>
      <file>
        <path>reference/TESTING_STRATEGY.md</path>
        <description>Current test coverage gaps and recommended approach</description>
      </file>
    </entries>
  </section>

  <section>
    <title>API Design</title>
    <entries>
      <file>
        <path>api/API_REFERENCE.md</path>
        <description>Full reference for all 13 exported functions</description>
      </file>
      <file>
        <path>api/EXPORTS_SPECIFICATION.md</path>
        <description>Exported function signatures and return values</description>
      </file>
      <file>
        <path>api/IMPORTS_GUIDE.md</path>
        <description>Dependency policy and importFrom() directives</description>
      </file>
      <file>
        <path>api/S3_CLASS_DESIGN.md</path>
        <description>S3 class "rsparrow" design and method dispatch</description>
      </file>
    </entries>
  </section>

  <section>
    <title>Implementation Support</title>
    <subtitle>Plan-execution support materials (detailed reference for implementors).</subtitle>
    <entries>
      <file>
        <path>implementation/PLAN_04_FILE_INVENTORY.md</path>
        <description>Per-file inventory of unPackList usage and eval(parse()) counts</description>
      </file>
      <file>
        <path>implementation/PLAN_04_SKELETON_IMPLEMENTATIONS.md</path>
        <description>Code templates for implementing exported API skeletons</description>
      </file>
      <file>
        <path>implementation/PLAN_04_SUBSTITUTION_PATTERNS.md</path>
        <description>Mechanical substitution patterns for eval(parse()) removal</description>
      </file>
    </entries>
  </section>

  <section>
    <title>Prompt Templates</title>
    <subtitle>AI prompt templates for future refactoring sessions.</subtitle>
    <entries>
      <file>
        <path>prompts/REFACTOR_PROMPT.md</path>
        <description>Main refactoring prompt for new Claude sessions</description>
      </file>
      <file>
        <path>prompts/archive/PROMPT_TASK2_TASK3.md</path>
        <description>Historical: Tasks 2-3 prompt (completed)</description>
      </file>
    </entries>
  </section>

  <section>
    <title>AI Guide</title>
    <entries>
      <file>
        <path>../CLAUDE.md</path>
        <description>Project guide for Claude Code (at repo root per convention)</description>
      </file>
    </entries>
  </section>
</documentation>
