# Code for the secondary findings paper

Code used in the *"Carrier frequencies of medically actionable pathogenic variants in Russian population"* scientific article (currently in review)

## System requirements

* 256+ GB of RAM
* Nvidia Parabricks-capable GPU
* SLURM HPC
* Singularity container engine

[Docker images](images) are intended to be converted to Singularity images.

[Bash scripts](bash) submit singularity images to be run on SLURM nodes.

## Naming conventions and storage

Sample ID is a 12-digit number, where first 6 digits mark its project.
Results are stored in directories `PROJECT/SAMPLE`.
Sample directory structure consists of:
* `/Alignments`
* `/Variation`
* `/Logs`
* `/Misc`
* ...and others

All files with results follow the same naming convention:

`SAMPLE.PLATFORM.PROGRAM_STACK.TYPE`

where program stack is a dot-separated left-to-right history of programs 
used to produce this file. 

## Copyright

© 2022-2026 Biotech Campus LLC for the National Genetic Initiative of Russia