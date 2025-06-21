Notes on memory

For small models, the MEMORY segment size tells how much heap.

For large models, the MEMPOOL tells how much heap. See z8kzork for an example.
Can set mempool to > 64K. For example, for z8kzork I do MEMPOOL(16000H).
I think that MEMPOOL must include more than just heap, because I have to set it to 16000H
to make room for allocating F000H worth of heap. Maybe it includes data+heap, or even
code+data+heap.
