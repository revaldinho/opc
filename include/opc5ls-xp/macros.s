# -----------------------------------------------------------------------------
# Macros
# -----------------------------------------------------------------------------

# set the cpu type to support conditional assembly
##define CPU_OPC5LSXP

##include "../opc5ls/macros.s"
##undef CPU_OPC5LS

MACRO   CPU_STRING()
    STRING "OPC5LSXP"
ENDMACRO

MACRO   CPU_BSTRING()
    BSTRING "OPC5LSXP"
ENDMACRO
