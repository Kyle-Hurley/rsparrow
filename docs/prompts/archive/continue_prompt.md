Continue executing Plan 04C (unPackList Removal) from docs/plans/PLAN_04C_UNPACKLIST_REMOVAL.md                          
                                                                                                                        
Review @CLAUDE.md and the memory file at                                                                                 
/home/kp/.claude/projects/-home-kp-Documents-projects-rsparrow-master/memory/MEMORY.md for project context.              
                                                                                                                        
Status of Plan 04C                                                                                                     
                                                                                                                    
Task 6 (12 estimation/prediction files) — PARTIALLY COMPLETE

Files DONE (unPackList removed, verified):
1. estimateFeval.R — unPackList removed, all 14 j-variable bare names replaced with data.index.list$jXXX
2. estimateFevalNoadj.R — same as above
3. estimateOptimize.R — unPackList removed (file.output.list), eval(parse()) loop replaced with nlfbOut[c(...)]
4. estimateNLLSmetrics.R — 2 unPackList calls removed, 2 eval(parse()) replaced with sitedata[[classvar[k]]] and
subdata[[classvar[1]]]
5. estimateNLLStable.R — all 5 unPackList calls removed (explicit local extractions), eval(parse()) for vANOVA.list
replaced, exists("ANOVAdynamic.list") → !is.null(ANOVAdynamic.list)
6. estimateWeightedErrors.R — unPackList removed (file.output.list vars extracted)
7. estimateBootstraps.R — unPackList removed (JacobResults + file.output.list vars extracted)
8. estimate.R — unPackList removed (estimate.input.list, file.output.list, class.input.list vars extracted)

Files REMAINING in Task 6 (need unPackList removal):
9. predict.R — 1 unPackList (unpacks JacobResults, datalstCheck, SelParmValues, estimate.input.list,
DataMatrix.list$data.index.list)
10. predictBoot.R — 1 unPackList
11. predictBootstraps.R — 1 unPackList (unpacks JacobResults, subdata columns, SelParmValues, predict.source.list,
file.output.list)
12. validateMetrics.R — 1 unPackList + 2 eval(parse()) on lines ~35 and ~39

Task 7 (29 data-prep files) — NOT STARTED

See the plan file for the full list of 24 files with unPackList + 5 eval/parse-only files.

Task 3 (Verification) — NOT STARTED

After both tasks: grep counts, R CMD build, update MEMORY.md.

Key patterns to follow

unPackList removal pattern:
# BEFORE:
unPackList(lists = list(data.index.list = DataMatrix.list$data.index.list), parentObj = list(NA))
# bare name: jstaid

# AFTER:
data.index.list <- DataMatrix.list$data.index.list
# use: data.index.list$jstaid

For parentObj = list(df = df) (column extraction from data.frame):
# BEFORE: extracts columns as bare names
# AFTER: varname <- df[["varname"]]  OR  df$varname

Dynamic column eval(parse()) pattern:
# BEFORE: eval(parse(text = paste0("subdata$", varname)))
# AFTER:  subdata[[varname]]

Do NOT modify files on the REMOVE list (25 files listed in the plan — Plan 05 deletes them).

applyUserModify.R warning: Complex eval(parse()) blocks that execute user-supplied R expressions should NOT be replaced —
flag with # TODO Plan 05 comment. Only replace the file.output.list unPackList and simple column-access eval(parse()).

Instructions

1. Finish Task 6 remaining 4 files (predict.R, predictBoot.R, predictBootstraps.R, validateMetrics.R)
2. Execute Task 7 (all 29 files)
3. Run verification: grep -c "unPackList" RSPARROW_master/R/*.R to check residual count
4. Run R CMD build --no-build-vignettes RSPARROW_master/ to verify build
5. Update MEMORY.md with completion status