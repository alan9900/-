param([string]$SourceRepository = 'https://github.com/MichaelWiesheu/MotorOptimization.git')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$work = Join-Path $projectRoot 'runtime/work'
$expected = 'e61673e10d4a7f164b713fb744e19bb69973f7e9'
function GitChecked([string[]]$Arguments) {
    & git @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Git failed: $($Arguments[0])" }
}
if (Test-Path -LiteralPath (Join-Path $work '.git')) {
    $actual = (& git -C $work rev-parse HEAD).Trim()
    if ($actual -ne $expected) { throw 'Existing runtime checkout has another commit; preserve it and use a fresh checkout.' }
    & git -C $work apply --reverse --check (Join-Path $PSScriptRoot 'execution_changes.patch') 2>$null
    if ($LASTEXITCODE -ne 0) { throw 'Existing checkout does not contain the expected patch; inspect it manually without overwriting a run.' }
    Write-Output 'Fixed upstream and observability patch already present; no files changed.'
    exit 0
}
New-Item -ItemType Directory -Force -Path (Split-Path $work -Parent) | Out-Null
GitChecked @('clone','--no-checkout','--filter=blob:none',$SourceRepository,$work)
GitChecked @('-C',$work,'sparse-checkout','init','--no-cone')
GitChecked @('-C',$work,'sparse-checkout','set','--no-cone',
    '/auxiliary/','/classes/','/derivatives/','/geometries/','/operators/','/packages/',
    '/results/opt_param/opt_param.m','/results/opt_evaluations/eval_init.m','/LICENSE','/README.md')
GitChecked @('-C',$work,'checkout','--detach',$expected)
GitChecked @('-C',$work,'apply','--check',(Join-Path $PSScriptRoot 'execution_changes.patch'))
GitChecked @('-C',$work,'apply',(Join-Path $PSScriptRoot 'execution_changes.patch'))
foreach ($subdir in @('data','figures','logs','work/results/opt_evaluations/data')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot "runtime/$subdir") | Out-Null
}
Write-Output "Ready: upstream $expected; parameter-only entries; original physics and solver settings preserved."
