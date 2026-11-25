@echo off
setlocal
rem Keep independently compiled kernels such as RMSNorm in eager mode.
set "TORCH_COMPILE_DISABLE=1"
pushd "%~dp0.." || exit /b 1
set "py=.venv-windows-gpu\Scripts\python.exe"
set "cli=.venv-windows-gpu\Scripts\rfd4-generate.exe"
if not exist "%py%" (
    uv venv --python 3.12.10 .venv-windows-gpu || goto failed
)
uv pip install --python "%py%" "uv==0.13.4" || goto failed
set "runtime_uv=.venv-windows-gpu\Scripts\uv.exe"
"%runtime_uv%" pip install --python "%py%" --torch-backend cu132 -e ".[all-cuda13]" || goto failed
"%runtime_uv%" pip check --python "%py%" || goto failed
"%py%" -c "import torch; assert torch.version.cuda == '13.2', torch.version.cuda; print(torch.cuda.get_device_name()); assert torch.ones(2, device='cuda').sum().item() == 2" || goto failed
set "CLUSTER=local"
if not defined DATA_PATH if not exist .env.local if not exist .env set "DATA_PATH=./data_path"
set "defaults=compile_lengths=null num_workers=0 nn.tri_mult_backend=torch nn.attention_type=torch ~metrics"
if "%~1"=="" goto smoke
"%cli%" %defaults% %* || goto failed
goto success

:smoke
set "run_id="
for /f %%i in ('%py% -c "import uuid; print(uuid.uuid4().hex)"') do set "run_id=%%i"
if not defined run_id goto failed
set "out=runs/windows-smoke-%run_id%"
"%cli%" %defaults% inputs=data/benchmarks/monomer/monomer-short.cif.zst num_replicates=1 out_dir=%out% || goto failed
"%py%" -c "from pathlib import Path; p=next(p for p in Path('%out%/inference_samples').rglob('*.cif') if p.stat().st_size); print(p.resolve())" || goto failed
:success
popd
exit /b 0

:failed
popd
exit /b 1
