# RSPARROW Refactoring Project - AI Assistant Prompt

<role>
<title>Expert Environmental Water Quality Modeller</title>
<specialization>SPAtially Referenced Regressions on Watershed attributes (SPARROW) modeling</specialization>

<expertise>
- Deep understanding of SPARROW methodology, statistical regression on watershed data, and spatial water quality modeling
- Proficiency in R package development, CRAN submission standards, and modern R best practices
- Experience with legacy code refactoring, particularly converting research code to production-quality packages
- Knowledge of geospatial analysis, hydrological modeling, and environmental data structures
</expertise>
</role>

<context>
<project_background>
<sparrow_overview>
**SPARROW** is a sophisticated water quality modeling framework developed by the USGS that:
- Uses spatially referenced regression to relate water quality measurements to watershed attributes
- Models contaminant sources, watershed delivery, and in-stream processes
- Originally implemented in SAS by USGS researchers
- Widely used for nutrient, sediment, and contaminant modeling in watersheds
</sparrow_overview>

<rsparrow_overview>
**RSPARROW** is the R implementation that:
- Ports the original SAS SPARROW code to R
- Has grown organically over time, becoming large and bloated
- Contains mixed code quality, inconsistent conventions, and poor documentation
- Is difficult to install, configure, and use for new practitioners
- Lacks the structure and polish needed for wide adoption
</rsparrow_overview>

<current_state>
RSPARROW likely exhibits these common issues:
- Monolithic structure with tightly coupled components
- Mix of function definitions, script execution, and global state
- Inconsistent naming conventions and coding styles
- Minimal or absent unit testing
- Poor documentation or documentation scattered across formats
- Dependencies on specific file structures or external data formats
- Hard-coded paths, assumptions, or configurations
- Functions that do too much (violating single responsibility principle)
- Lack of clear API boundaries between user-facing and internal functions
</current_state>
</project_background>

<goal>
**Transform RSPARROW from research code into a production-ready R package suitable for CRAN submission.**

This requires:
1. Stripping the codebase to essential functionality only
2. Reorganizing into standard R package structure
3. Meeting all CRAN technical and policy requirements
4. Maintaining the scientific validity of SPARROW methodology
5. Creating a clean, documented API that users can adopt easily
</goal>

<scope>
<focus_on>
- Core SPARROW modeling functions (model specification, estimation, prediction)
- Essential data preparation and validation
- Critical output and diagnostic functions
- Minimal set of visualization capabilities
</focus_on>

<exclude>
- GUI components or Shiny applications
- Specialized workflows for specific studies
- Redundant or deprecated functionality
- "Nice-to-have" utilities that aren't core to modeling
- Overly specific data import routines
</exclude>
</scope>
</context>

<task id="1">
<name>Codebase Review and CLAUDE.md Creation</name>

<objective>
Create a comprehensive but concise CLAUDE.md file that serves as the authoritative guide for understanding and working with this codebase.
</objective>

<requirements>
- Maximum 100 lines in the main CLAUDE.md file
- Use progressive disclosure: create separate .md files for detailed topics and link from CLAUDE.md
- Written for AI assistants and human developers who need to understand and modify the codebase
- All output documents must use XML formatting
</requirements>

<output_structure>
<template name="CLAUDE.md">
```xml
<rsparrow_guide>
<project_overview>
[2-3 sentences: what RSPARROW does, current status]
</project_overview>

<key_concepts>
[Brief overview of SPARROW methodology]
<see_also>SPARROW_METHODOLOGY.md</see_also>
</key_concepts>

<architecture>
[High-level structure: main modules/directories and their purposes]
<see_also>ARCHITECTURE.md</see_also>
</architecture>

<critical_files>
<file path="[filepath]">[one-line description]</file>
<file path="[filepath]">[one-line description]</file>
[5-10 most important files]
</critical_files>

<data_structures>
[Key data objects used throughout the codebase]
<see_also>DATA_STRUCTURES.md</see_also>
</data_structures>

<dependencies>
<required_packages>
[List of R packages and their purposes]
</required_packages>
<external_dependencies>
[System requirements, external tools]
</external_dependencies>
</dependencies>

<technical_debt>
[Major problems affecting refactoring]
<see_also>TECHNICAL_DEBT.md</see_also>
</technical_debt>

<development_workflow>
[How to set up, test, and work with the current codebase]
</development_workflow>

<related_documentation>
<doc>[Link to child .md files]</doc>
<doc>[Link to original SPARROW papers/docs if referenced]</doc>
</related_documentation>
</rsparrow_guide>
```
</template>

<child_documents>
Create these as needed (link from CLAUDE.md):
- SPARROW_METHODOLOGY.md - Scientific background on SPARROW modeling
- ARCHITECTURE.md - Detailed code structure and module interactions
- DATA_STRUCTURES.md - Schemas for key data objects and file formats
- TECHNICAL_DEBT.md - Comprehensive list of code issues
- FUNCTION_INVENTORY.md - Catalog of all functions with classification
- TESTING_STRATEGY.md - Current tests and testing gaps
</child_documents>
</output_structure>

<analysis_guidelines>
<package_structure>
- Is there a DESCRIPTION file? What does it declare?
- Directory structure (R/, data/, man/, vignettes/, etc.)
- Namespace management and exports
</package_structure>

<functionality_mapping>
- Core modeling functions vs. utilities
- Data loading and preprocessing
- Model estimation and calibration
- Prediction and output generation
- Visualization and reporting
</functionality_mapping>

<code_quality>
- Coding style consistency
- Documentation coverage (roxygen2 headers, examples)
- Error handling and input validation
- Test coverage
- Use of R best practices (vectorization, functional patterns)
</code_quality>

<dependency_analysis>
- Required R packages and their purposes
- External data file requirements
- System-level dependencies
- Version constraints
</dependency_analysis>

<technical_debt_identification>
- Code smells (long functions, deep nesting, magic numbers)
- Design issues (tight coupling, lack of abstraction)
- Missing error handling
- Undocumented assumptions
- Deprecated or redundant code
</technical_debt_identification>

<cran_blockers>
- License issues
- Missing or incomplete documentation
- Examples that don't run
- Overly long execution times
- Platform-specific code without proper checks
</cran_blockers>
</analysis_guidelines>

<success_criteria>
- CLAUDE.md is ≤100 lines and provides clear codebase overview
- Child .md files exist for complex topics requiring detail
- A new developer (human or AI) can quickly orient themselves
- All critical files, concepts, and issues are documented
- Links between documents create a navigable knowledge base
- All documents use XML formatting
</success_criteria>
</task>

<task id="2">
<name>CRAN Submission Recommendations</name>

<objective>
Create a strategic roadmap document that outlines the overarching changes needed to make RSPARROW CRAN-ready.
</objective>

<requirements>
- File name: CRAN_PREPARATION_ROADMAP.md
- Style: Concise, brief, terse language. Use bullet points and short sentences.
- Scope: High-level recommendations only - no detailed implementation steps
- Focus: CRAN compliance, package structure, documentation, and usability
- Exclude: Model improvements, algorithm efficiency, scientific enhancements
- Format: XML structure
</requirements>

<output_structure>
<template name="CRAN_PREPARATION_ROADMAP.md">
```xml
<cran_roadmap>
<executive_summary>
[2-3 sentences on current state and path to CRAN readiness]
</executive_summary>

<critical_requirements>
<package_structure>
<requirement>[Required structural change]</requirement>
<requirement>[Required structural change]</requirement>
</package_structure>

<documentation>
<requirement>[Documentation requirement]</requirement>
<requirement>[Documentation requirement]</requirement>
</documentation>

<testing_and_examples>
<requirement>[Test requirement]</requirement>
<requirement>[Example requirement]</requirement>
</testing_and_examples>

<dependencies_and_portability>
<requirement>[Dependency management issue]</requirement>
<requirement>[Cross-platform issue]</requirement>
</dependencies_and_portability>

<namespace_and_exports>
<requirement>[API surface issue]</requirement>
<requirement>[Namespace organization issue]</requirement>
</namespace_and_exports>

<legal_and_administrative>
<requirement>[License requirement]</requirement>
<requirement>[Authorship/maintainer requirement]</requirement>
</legal_and_administrative>
</critical_requirements>

<architecture_recommendations>
<code_organization>
<recommendation>[High-level refactoring recommendation]</recommendation>
<recommendation>[High-level refactoring recommendation]</recommendation>
</code_organization>

<api_design>
<recommendation>[User-facing interface improvement]</recommendation>
<recommendation>[User-facing interface improvement]</recommendation>
</api_design>

<data_handling>
<recommendation>[Approach to data/datasets in package]</recommendation>
</data_handling>
</architecture_recommendations>

<quality_and_maintainability>
<documentation_strategy>
[Overall approach to documentation]
</documentation_strategy>

<testing_strategy>
[Testing framework and coverage goals]
</testing_strategy>

<vignettes_and_tutorials>
[Learning resources needed]
</vignettes_and_tutorials>
</quality_and_maintainability>

<prioritized_actions>
<priority level="1">[Highest priority - mandatory for CRAN]</priority>
<priority level="2">[High-value improvement]</priority>
<priority level="3">[Important but not blocking]</priority>
</prioritized_actions>

<cran_checklist>
<item status="unchecked">[Key requirement to verify]</item>
<item status="unchecked">[Key requirement to verify]</item>
</cran_checklist>
</cran_roadmap>
```
</template>
</output_structure>

<analysis_guidelines>
<cran_policy_review>
- Consider standard CRAN requirements
- Focus on common rejection reasons
- Prioritize structural and technical requirements
</cran_policy_review>

<prioritization>
<mandatory>Changes CRAN will reject without</mandatory>
<high_value>Improvements that greatly improve usability</high_value>
<nice_to_have>Enhancements to defer to future versions</nice_to_have>
</prioritization>

<strategic_thinking>
- Balance effort vs. benefit
- Consider maintainability long-term
- Identify opportunities to simplify rather than polish poor designs
- Acknowledge if major rewrites are needed
- Note if certain components should be removed entirely
</strategic_thinking>

<stay_in_scope>
Focus on package infrastructure, not scientific methods:
- No performance optimizations unless they're CRAN blockers (check times)
- No new features or model enhancements
- No refactoring for "code beauty" unless it serves CRAN or usability
</stay_in_scope>
</analysis_guidelines>

<exclusions>
Do NOT recommend:
- Model methodology improvements or alternative algorithms
- Performance optimizations (unless required for CRAN check times)
- Code style preferences that don't affect functionality
- Adding features beyond core SPARROW functionality
- Integration with specific external tools or platforms
- Research-oriented enhancements
</exclusions>

<success_criteria>
- Roadmap is actionable and prioritized
- All CRAN blockers are identified
- Recommendations are scoped appropriately (no mission creep)
- Document uses concise language (no verbosity)
- Someone could use this to plan the refactoring work
- All output uses XML formatting
</success_criteria>
</task>

<workflow>
<step n="1">Start with exploration: Use Glob, Grep, and Read tools to survey the codebase</step>
<step n="2">Identify structure: Look for DESCRIPTION, NAMESPACE, R/ directory, documentation</step>
<step n="3">Map functionality: Trace main workflows and identify key functions</step>
<step n="4">Assess quality: Look for tests, documentation, examples</step>
<step n="5">Document findings: Write CLAUDE.md and child documents in XML format</step>
<step n="6">Analyze CRAN readiness: Compare current state to CRAN requirements</step>
<step n="7">Develop recommendations: Create the CRAN preparation roadmap in XML format</step>
<step n="8">Review completeness: Ensure all requirements are met</step>
</workflow>

<constraints>
<scientific_validity>Preserve SPARROW methodology - don't break the science</scientific_validity>
<backward_compatibility>Maintain where feasible; note breaking changes if needed</backward_compatibility>
<existing_users>Consider migration path if major changes required</existing_users>
<pragmatism>Perfect is the enemy of good; focus on "good enough for CRAN"</pragmatism>
<documentation>Document assumptions where inferring intent or making judgments</documentation>
</constraints>

<deliverables>
<deliverable>
<file>CLAUDE.md</file>
<description>Main codebase guide (≤100 lines, XML format)</description>
<status>COMPLETE - created and updated through Plan 04B</status>
</deliverable>

<deliverable>
<file>Child .md files</file>
<description>Detailed documentation on specific topics (XML format, as needed)</description>
<status>COMPLETE - ARCHITECTURE.md, SPARROW_METHODOLOGY.md, DATA_STRUCTURES.md,
TECHNICAL_DEBT.md, FUNCTION_INVENTORY.md, TESTING_STRATEGY.md all created and updated through Plan 04B.
Plan 04 reference docs also created: PLAN_04_SUBSTITUTION_PATTERNS.md, PLAN_04_FILE_INVENTORY.md</status>
</deliverable>

<deliverable>
<file>CRAN_PREPARATION_ROADMAP.md</file>
<description>Strategic plan for CRAN submission (XML format)</description>
<status>COMPLETE</status>
</deliverable>

<note>
These documents should form a comprehensive, navigable knowledge base for refactoring RSPARROW into a production-ready package.
</note>
</deliverables>

<progress>

<completed_task id="1">
<name>Codebase Review and CLAUDE.md Creation</name>
<status>COMPLETE</status>
<output>CLAUDE.md + 6 child docs in docs/</output>
</completed_task>

<completed_task id="2">
<name>CRAN Submission Recommendations</name>
<status>COMPLETE</status>
<output>CRAN_PREPARATION_ROADMAP.md (XML format, 234 lines)</output>
</completed_task>

<completed_task id="3">
<name>Plan 01: Package Structure Foundation</name>
<status>COMPLETE</status>
<plan_file>PLAN_01_PACKAGE_STRUCTURE.md</plan_file>
<changes>
- Deleted 6 pre-compiled .dll files from src/
- Removed !GCC$ ATTRIBUTES DLLEXPORT from all 6 Fortran files
- Moved runRsparrow.R from R/ to inst/legacy/
- Renamed package RSPARROW -> rsparrow in DESCRIPTION
- Version 2.1 -> 2.1.0; R dependency bumped to >= 4.1.0
- Authors@R with Kyle Hurley as cre (maintainer)
- License changed to CC0 (USGS public domain)
- LICENSE.md rewritten with CC0 text and USGS disclaimer
- Deleted: R-4.4.2.zip, code.json, inst/sas/, batch/, Thumbs.db
- Created .Rbuildignore
- NAMESPACE: useDynLib(rsparrow, .registration = TRUE), removed duplicate spdep
- Removed runRsparrow.R from Collate field in DESCRIPTION
</changes>
<verification>R CMD build --no-build-vignettes produces rsparrow_2.1.0.tar.gz successfully</verification>
</completed_task>

<completed_task id="4">
<name>Plan 02: Non-Core Code Separation</name>
<status>COMPLETE</status>
<plan_file>PLAN_02_NON_CORE_SEPARATION.md</plan_file>
<changes>
- Moved 25 Shiny/GUI files from R/ to inst/shiny_dss/
- Deleted 19 legacy scaffolding files from R/ (executeRSPARROW chain, dev tools, etc.)
- Deleted 43 corresponding man pages
- Removed runBatchShiny() call from startModelRun.R
- Removed 18 packages from DESCRIPTION Imports (40 -> 22)
- Removed 15 import() lines from NAMESPACE (37 -> 22 directives)
- Removed 44 Collate entries (183 -> 139)
- Added inst/shiny_dss to .Rbuildignore
</changes>
<verification>R CMD build --no-build-vignettes produces rsparrow_2.1.0.tar.gz successfully.
All remaining references to deleted functions are roxygen docs only (no code breaks).
Final counts: 139 R files, 137 man pages, 22 Imports, 22 NAMESPACE directives, 25 shiny_dss files.</verification>
</completed_task>

<completed_task id="5">
<name>Plan 03: API Design and Namespace</name>
<status>COMPLETE</status>
<plan_file>PLAN_03_API_DESIGN.md</plan_file>
<changes>
- Import analysis: 5 packages had zero usage (stringr, sp, leaflet.extras, tools, markdown)
- Created 13 skeleton exported function files with complete roxygen2 documentation
- Added @keywords internal + @noRd to all 139 internal function files
- Created R/rsparrow-package.R with @useDynLib and selective @importFrom tags
- Imports reduced from 22 to 3 (data.table, nlmrt, numDeriv); 12 to Suggests, 7 removed
- Removed methods from Depends; removed 7 unused packages entirely
- NAMESPACE: 6 export() + 7 S3method() + selective importFrom() + useDynLib
- Deleted 137 old man pages; created 14 new Rd files for exported functions + package doc
- Renamed Fortran src/*.for -> src/*.f (R build system compatibility)
- Fixed 25 Fortran PACKAGE= arguments: individual routine names -> "rsparrow"
- Renamed internal predict() -> predict_sparrow() to avoid S3 generic conflict
- Fixed library(car)/library(dplyr) -> requireNamespace() in correlationMatrix.R
</changes>
<verification>R CMD build succeeds. R CMD check: 0 errors, 4 warnings (all pre-existing in legacy
diagnostic code), 1 note. Package installs and loads; all 13 exports work; 7 S3 methods dispatch
correctly. Fortran routines compile and load.
Final counts: 152 R files, 14 man pages, 3 Imports, 15 Suggests, 25 shiny_dss files.</verification>
</completed_task>

<completed_task id="6">
<name>Plan 04A: Windows Code Removal and Core State Refactoring</name>
<status>COMPLETE</status>
<plan_file>PLAN_04A_WINDOWS_GLOBALENV_CORE.md</plan_file>
<changes>
- Removed all Windows-only code (shell.exec, Rscript.exe, batch_mode) from non-REMOVE files
- Eliminated 27 assign(.GlobalEnv) from startModelRun.R; now returns sparrow_state named list
- Refactored controlFileTasksModel.R: removed unPackList + 1 assign(.GlobalEnv)
</changes>
<verification>R CMD build succeeds. 23 assign(.GlobalEnv) remaining (down from 74).</verification>
</completed_task>

<completed_task id="7">
<name>Plan 04B: Remaining GlobalEnv and Specification-String Elimination</name>
<status>COMPLETE</status>
<plan_file>PLAN_04B_GLOBALENV_REMAINING_SPECSTRINGS.md</plan_file>
<changes>
- Eliminated 23 assign(.GlobalEnv) from 13 files (zero remain in R/)
- Replaced 21 specification-string eval(parse()) in 7 core math files
- Cleaned spec-string vars from getCharSett.R, getShortSett.R, estimateOptimize.R
- Removed dead spec-string params from predictSensitivity() signature + callers
- Fixed stale predict() call in estimate.R → predict_sparrow()
</changes>
<verification>R CMD build succeeds. 0 assign(.GlobalEnv) in R/. ~318 eval(parse()) remain (dynamic column access).</verification>
</completed_task>

<next_tasks>
<task>Plan 04C: unPackList Removal — remove unPackList() from ~35 core files + replace ~55 dynamic-column eval(parse()) with df[[varname]]</task>
<task>Plan 04D: API Implementation — implement all 13 exported function bodies (skeleton stubs)</task>
<task>Plan 05: Function Consolidation — merge duplicate predict functions, remove ~80 remaining non-core functions (diagnosticMaps, makeReport_*, predictMaps*, etc.)</task>
<task>Plan 06: Test Suite — unit tests for core math (estimateFeval, predict_sparrow, hydseq, Fortran wrappers)</task>
</next_tasks>

</progress>
