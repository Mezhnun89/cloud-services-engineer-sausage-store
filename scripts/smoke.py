import json,sys,urllib.request
base=sys.argv[1]
def req(path,data=None):
 body=None if data is None else json.dumps(data).encode()
 r=urllib.request.urlopen(urllib.request.Request(base+path,data=body,headers={'Content-Type':'application/json'}),timeout=30)
 return r.status,r.read()
status,body=req('/')
assert status==200 and b'<app-root' in body
_,body=req('/api/products'); products=json.loads(body)
assert len(products)==6,products
status,body=req('/api/orders',{'productOrders':[{'product':{'id':1},'quantity':2}]})
order=json.loads(body)
assert status==201 and order['id']>10000 and order['status']=='PAID',order
assert order['totalOrderPrice']==640.0,order
print('PASS: frontend, six products, order after seeded identity, total 640')
