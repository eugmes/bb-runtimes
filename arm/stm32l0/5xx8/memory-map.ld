MEMORY
{
  flash  (rx) : ORIGIN = 0x08000000, LENGTH = 64K
  sram  (rwx) : ORIGIN = 0x20000000, LENGTH = 8K
}

REGION_ALIAS("sram_tx", sram)
REGION_ALIAS("sram_ro", sram)
REGION_ALIAS("sram_bs", sram)
REGION_ALIAS("sram_da", sram)
