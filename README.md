
1581 Partition Swap

by AKX/AKX38


This project aims to offer a lightweight and convenient way to quickly list and select partitions from a Commodore 1581 drive attached to a Commodore 64 computer. It was developed natively on a C64 using Turbo Macro Pro 1.2 by Style.

I have adapted some example code provided by Commodore on the 1581 Test Disk provided with each drive, but have ported all the code to 6510 ASM and removed some bloat.

I aim to implement a navigation menu rather than a text prompt to select the next partition.

Current Version: 1.02
Many thanks to Oziphantom from Lemon64 for suggestions

Files:

partswap1.asm - SEQ file for TMP 1.2, load with [command] + E, readable in github

partswap1.s   - PRG file for TMP 1.2, load with [command] + L

partswap1    - PRG file, Executable

partswap.d64  - D64 disk image containing all three files
