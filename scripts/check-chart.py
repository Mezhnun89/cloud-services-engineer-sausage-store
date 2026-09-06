import sys,yaml
items=list(yaml.safe_load_all(open(sys.argv[1])))
apps=[x for x in items if x and x['kind'] in ('Deployment','StatefulSet')]
assert len(apps)==5
for x in apps:
 for c in x['spec']['template']['spec']['containers']:
  assert all(k in c['resources'][v] for v in ['requests','limits'] for k in ['cpu','memory'])
assert len([x for x in items if x and x['kind']=='Service'])==5
# Worst case: backend surge (2), HPA at max (3), frontend (1), two DBs.
counts={'backend':2,'backend-report':3,'frontend':1,'postgresql':1,'mongodb':1}
totals={k:0 for k in ('requests_cpu','limits_cpu','requests_memory','limits_memory')}
for x in apps:
 for c in x['spec']['template']['spec']['containers']:
  for typ in ['requests','limits']:
   cpu=c['resources'][typ]['cpu']; mem=c['resources'][typ]['memory']
   totals[typ+'_cpu']+=counts[c['name']]*(int(cpu[:-1]) if cpu.endswith('m') else int(cpu)*1000)
   totals[typ+'_memory']+=counts[c['name']]*int(mem[:-2])
assert totals['requests_cpu']<=2000 and totals['limits_cpu']<=3000, totals
assert totals['requests_memory']<=1000 and totals['limits_memory']<=2500, totals
print('Chart structure and simultaneous rollout/HPA quota: PASS',totals)
