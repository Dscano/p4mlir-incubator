set(LIBS
  P4MLIR_P4HIR
  P4MLIR_P4CoreLib
  P4MLIRConversion
  P4MLIRTransforms
  P4MLIRConversion

  MLIRFuncDialect
  MLIROptLib
)

add_llvm_executable(p4mlir-opt p4mlir-opt.cpp)

llvm_update_compile_flags(p4mlir-opt)
target_link_libraries(p4mlir-opt PRIVATE ${LIBS})

mlir_check_all_link_libraries(p4mlir-opt)
