## Setup
[Download and install ALE](http://www.arcadelearningenvironment.org/downloads/). 
Instructions for installation are in the ale folder in manual.pdf.

Clone this repo and run following (note: it'll be different for your system)

```
mkfifo in.fifo
mkfifo out.fifo 
ln -s ~/Downloads/ale_0.4.4/ale_0_4/ale ale
ln -s ~/Downloads/roms roms
```

Symbolically link to this repo from inside the ALE installation. Something similar to `$ ln -s ~/src/deep-learning/project/ deep`
