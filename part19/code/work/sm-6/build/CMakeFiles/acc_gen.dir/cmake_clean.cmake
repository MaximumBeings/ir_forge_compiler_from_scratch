file(REMOVE_RECURSE
  "include/mg/MgOps.cpp.inc"
  "include/mg/MgOps.h.inc"
  "include/mg/MgOpsDialect.cpp.inc"
  "include/mg/MgOpsDialect.h.inc"
)

# Per-language clean rules from dependency scanning.
foreach(lang )
  include(CMakeFiles/acc_gen.dir/cmake_clean_${lang}.cmake OPTIONAL)
endforeach()
