#!/usr/bin/env python3
"""Generate a private Secret JSON for kubectl/GitHub; never print its values."""
import argparse,json,os,secrets
p=argparse.ArgumentParser()
p.add_argument('output')
p.add_argument('--release',default='sausage-store')
a=p.parse_args()
pg,root,reports=[secrets.token_hex(24) for _ in range(3)]
x={'apiVersion':'v1','kind':'Secret','metadata':{'name':'sausage-store-db'},'type':'Opaque','stringData':{'postgres-password':pg,'mongo-root-password':root,'reports-password':reports,'mongodb-uri':f'mongodb://reports:{reports}@{a.release}-mongodb:27017/sausage-store?authSource=sausage-store'}}
f=os.open(a.output,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
with os.fdopen(f,'w') as stream: json.dump(x,stream)
print('Secret file created with mode 0600; store privately and do not regenerate after installing the databases.')
