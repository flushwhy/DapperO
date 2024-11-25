@echo off 

odin build . -out:dappero.exe -strict-style -vet -no-bounds-check -o:speed -subsystem:windows