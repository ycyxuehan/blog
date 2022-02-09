# 删除处于terminating状态无法删除的资源

以namespace为例

```bash
cat <<EOF >/tmp/m.json
{
    "apiVersion": "v1",
    "kind": "Namespace",
    "metadata": {
        "name": "monitoring"
    }
}
EOF

kubectl proxy

curl -k -H 'Content-Type:application/json' -X PUT --data-binary @/tmp/m.json http://127.0.0.1:8001/api/v1/namespaces/monitoring/finalize
````