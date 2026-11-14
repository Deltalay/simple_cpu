$ErrorActionPreference = "Stop"

$OSS = "C:\oss-cad-suite\bin"

$env:Path = "$OSS;C:\oss-cad-suite\lib;$env:Path"

Write-Host "== Yosys =="
yosys -p "read_verilog cpu.v flash.v memory.v; synth_gowin -top top -json cpu.json"

Write-Host "== nextpnr =="
nextpnr-himbaechel `
    --json cpu.json `
    --write pnrcpu.json `
    --device GW1NR-LV9QN88PC6/I5 `
    --vopt family=GW1N-9C `
    --vopt cst=cpu.cst

Write-Host "== Pack =="
gowin_pack `
    -d GW1N-9C `
    -o cpu.fs `
    pnrcpu.json

Write-Host "== Program =="
openFPGALoader -b tangnano9k cpu.fs

Write-Host "== DONE =="
