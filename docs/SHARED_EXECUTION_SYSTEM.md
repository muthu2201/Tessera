# Shared execution system

`tessera_execution_system` routes each accepted command through one round-robin dispatcher to either the vector ALU or tensor multiply-accumulate tile. Both units return client ID, tag, status, and a 32-bit result through one completion FIFO. The live-tag scoreboard blocks duplicate outstanding client/tag pairs. Simulation and synthesis are being added as separate CI jobs.
