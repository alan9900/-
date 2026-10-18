"""Create a deterministic integrity manifest; excludes runtime and itself."""
from pathlib import Path
import csv, hashlib
root=Path(__file__).resolve().parents[2]
target=root/'docs/FILE_MANIFEST.csv'
items=[]
for path in sorted(root.rglob('*')):
    if not path.is_file(): continue
    relative=path.relative_to(root)
    if any(p in {'runtime','external','__pycache__'} for p in relative.parts) or path==target: continue
    if relative.parts[0]=='results':
        provenance='local_run'
        if path.name=='paper_parameter_comparison.csv': provenance='local_run + paper_reference'
    elif relative.parts[:2]==('src','original'): provenance='upstream_reference'
    elif relative.parts[0]=='reports': provenance='local_run_report'
    else: provenance='reproduction_documentation_or_code'
    content=path.read_bytes()
    assert len(content)<100*1024**2,relative
    items.append((relative.as_posix(),len(content),hashlib.sha256(content).hexdigest(),provenance))
with target.open('w',encoding='utf-8',newline='') as f:
    writer=csv.writer(f,lineterminator='\n'); writer.writerow(['path','bytes','sha256','provenance']); writer.writerows(items)
print(f'{len(items)} files; {sum(row[1] for row in items):,} bytes; largest {max(row[1] for row in items):,} bytes')
