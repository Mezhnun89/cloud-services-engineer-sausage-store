#!/usr/bin/env bash
set -euo pipefail
mkdir -p verification/raw
for component in backend backend-report frontend; do
  kind load docker-image "mezhnun/sausage-$component:ci" --name sausage-ci
done
kubectl create namespace sausage-test
umask 077
python3 - <<'SECRET'
import secrets,json
p=secrets.token_hex(24); m=secrets.token_hex(24); a=secrets.token_hex(24)
x={'apiVersion':'v1','kind':'Secret','metadata':{'name':'sausage-store-db','namespace':'sausage-test'},'stringData':{'postgres-password':p,'mongo-root-password':m,'reports-password':a,'mongodb-uri':f'mongodb://reports:{a}@sausage-store-mongodb:27017/sausage-store?authSource=sausage-store'}}
open('/tmp/db-secret.json','w').write(json.dumps(x))
SECRET
kubectl apply -f /tmp/db-secret.json
helm upgrade --install sausage-store sausage-store-chart -n sausage-test   --set global.imageTag=ci --set backend.vpa.enabled=false --set backend-report.hpa.enabled=false   --wait --timeout 5m
kubectl exec -n sausage-test sausage-store-postgresql-0 -- psql -U store -d store -Atc   "SELECT version,success FROM flyway_schema_history ORDER BY installed_rank; SELECT count(*) FROM orders;" | tee verification/raw/migrations.txt
kubectl port-forward -n sausage-test svc/sausage-store-frontend 8088:8080 > /tmp/pf.log 2>&1 &
pf=$!
trap 'kill "$pf" 2>/dev/null || true' EXIT
for i in $(seq 1 30); do curl -fsS http://127.0.0.1:8088/healthz && break; sleep 1; done
python3 scripts/smoke.py http://127.0.0.1:8088 | tee verification/raw/smoke.txt
# A replaced PostgreSQL pod must retain the new order on its PVC.
kubectl delete pod -n sausage-test sausage-store-postgresql-0
kubectl wait -n sausage-test --for=condition=Ready pod/sausage-store-postgresql-0 --timeout=180s
kubectl exec -n sausage-test sausage-store-postgresql-0 -- psql -U store -d store -Atc   'SELECT count(*) FROM orders WHERE id>10000;' | tee verification/raw/persistence.txt
test "$(tail -n1 verification/raw/persistence.txt)" = 1
helm list -n sausage-test -o json > verification/raw/helm.json
echo 'INTEGRATION_OK: migrations, catalog, new order, persistent data'
