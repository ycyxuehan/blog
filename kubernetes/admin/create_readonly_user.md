# 创建一个只读用户

创建证书

```bash
mkdir temp
cd temp
USER=viewer
openssl genrsa -out ${USER}.key 2048
openssl req -new -key ${USER}.key -out ${USER}.csr -subj "/CN=${USER}"
openssl x509 -req -in ${USER}.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out ${USER}.crt -days 365
```

创建用户

```bash
kubectl create clusterrolebinding kubernetes-viewer --clusterrole=view --user=${USER}
```

修改配置

```bash
cp -a ~/.kube/config ./config
vim config
```

config示例, 替换其中的${USER}为你的用户名，替换`client-certificate-data`和`client-key-data`为对应值

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMvakNDQWVhZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeE1Ea3hNekE1TWprek4xb1hEVE14TURreE1UQTVNamt6TjFvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTW4wCmZlaUZuR1pvVjZEVGpabk5zME5UN2ZaRzd4UDQrOVF1eDd6MnRCZ0swVkVzRFhVUEx6VE4wLzNVdXdWaDFYeGwKRmJFNEQrcUJYVjFwLzU1TVBUcGRQWjBQdzVUZlN5NFp6bm1vOTY5cHorNW9OVmtjQnVIMFJFbzB6NjcxNDFYZQphcXFIZnNVcWx4QWJvWUxsV3FoWkp2Sm9JZlBFYXFObE5xUitaaFhmWkhXY0pCRC9OQTB2dXNtVmszVzRTV3VECnF2QUt1MHBVT0RKTnpTcTFpWWx4WG1JUEszNEZQQmVhYnAyb2gxWVMrbVVmNUZMcnM5T05hSUkwSEMyQ3VKRDgKcGtIOTJaakNhT3RrSTVZajcxcEZ0YytQcGQwN0d2OS9DTUxpbGgxSGlwbVBEM2lwMkFUSlFSb01tSnFrcjgvRQpxMjBYbUlkNFh4YXphd1gxR0o4Q0F3RUFBYU5aTUZjd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZQNndyYlBTc2xyWUhxUGMxU25vbTJWdk4rV3hNQlVHQTFVZEVRUU8KTUF5Q0NtdDFZbVZ5Ym1WMFpYTXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBRkRSaTR5ZXNHKzlTWk10cy9lcAoxcXdIdnBQOUpraHRXbnBlTndaRzlzcU1BSW9TeHcvK01CNXh4RXRnSzhqTk00NzFvWmxVV3IzZ01vTGNmUUVMCmtvVHNTNTgwV1ZXd1pOODd1QnBqV3I0dWdEWmJoalBBM0hRcVdJdTNMYmd1WUJJdmlVOTFoZU5UKzlFYk9qSlgKVXFwamlnbmw1QVZkSThhYmxNcHZEUnBDZ0lFQjRVQnN4R21BU3BZaTJtSmVqSVNUbTR4U1lGdnZVcC80Q1JzaQpBNUZ4b1FvSjN5MUJHam45a0ZCQ0E0UzFFUlFPMWRFZUhDRVZwQnlRRFhIa0pGb0VZZHBtSTNEYjgvMmlUSTNDCkFSUzBPdGVVejd6Y2tGYzNsbnVxUUtzUnE5V0JQWXdtWlN5ZFZ0dmo2NVZEcVhycWwvVWZOWjFSdTlwU25kQlUKL09rPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    server: https://10.0.1.43:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: ${USER}
  name: ${USER}@kubernetes
current-context: ${USER}@kubernetes
kind: Config
preferences: {}
users:
- name: intbee
  user:
    # data from result of command: cat ${USER}.crt | base64 --wrap=0
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNyVENDQVpVQ0ZIRDQwd25lbzJCR2RKUGZjWEdwMjVzcVZNcEhNQTBHQ1NxR1NJYjNEUUVCQ3dVQU1CVXgKRXpBUkJnTlZCQU1UQ210MVltVnlibVYwWlhNd0hoY05NakV4TVRBNU1EY3pOakl6V2hjTk1qSXhNVEE1TURjegpOakl6V2pBUk1ROHdEUVlEVlFRRERBWnBiblJpWldVd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3CmdnRUtBb0lCQVFDeVZwdk1IcmNCMmJ6NG54bTNYNnJtQzQ0Z0ZsWnlSelBnUDRyNyswSjBEUXVLdzNyZ2VGSE0KZnZaN1N1RzhRMUQ2RlJHWi9EdCt6UGorWDZiYWZ4aFFMb3Z6eGRYQmpCUnBHUFdaUjcxS3UwSk5CWkNWY3dYSgpORmNZcDI1WVl3QUsreEpDSU0vaENzQnJEdWpZRFVYM1d3a0tXYVRGS21BVlBXNTBCTkJqQzVlMy9xTGxsdTVPCk1ETW1YL0xNZGtTWG1XaDZWdjZtQmRNS3ZlY3cxK2VndTI4dS9Kam9pWnBJNWM0aTdKNmd5ZzdvREZHMDlKZ1EKVGU5VkNoSHp1ckpvZWRaTUtFTTlOMVBOYVFkMW9aU29vOFdCUHJoQzRma3I2V3BiVnJES0QxTlFIWUlCdWtWVgpRRS9HY0c1Mkl6WkJ4N0djOWM3c0NJTWtkdEtQQzdOUkFnTUJBQUV3RFFZSktvWklodmNOQVFFTEJRQURnZ0VCCkFGSmhCcW9pOVRHdCt6cGlITHgwV1FJakNMQy9LZitqOU5lTU44MnJweVhhQlZNNVN2U1dRVjdwaTFIN2RpdHYKUkJGK2VwVXBuNlNSOHNPMlNkRjF5N2ZzV0VEaUc5K2VzWHdlUFNZdDZxd3Z5UjZJSEFSaGU3M1ZTWkZyZ08wOQp4ZVBWYjlBRndzUnRqVkZZUk5wNzNMd1o4bnhWM3JOdkF3YzdudGl3dkRQSEdMV0pFU0pTVDVlSTh3dlFlM2V1Ck15dHEzeVF6WWxPVVdJcFhRMysyaGU1L1lLRml1UUNldFBpTHBybytCS0FTMmoyV3RnS3JmeFRIU0JCQ0RjMGoKbHh1WkJrWkRFTGdDUVN2UXdtN0VhMXljUXpsUlF5dFh6YUc2cFY4d3Uvb2lBdG9vbnBWd2lWekdaVjdoODFhRgpHOWc0TVlMS0ordU12c0ptMzJtOFViWT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=

   # data from result of command: cat ${USER}.key | base64 --wrap=0
    client-key-data:  LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBc2xhYnpCNjNBZG04K0o4WnQxK3E1Z3VPSUJaV2NrY3o0RCtLKy90Q2RBMExpc042CjRIaFJ6SDcyZTByaHZFTlEraFVSbWZ3N2ZzejQvbCttMm44WVVDNkw4OFhWd1l3VWFSajFtVWU5U3J0Q1RRV1EKbFhNRnlUUlhHS2R1V0dNQUN2c1NRaURQNFFyQWF3N28yQTFGOTFzSkNsbWt4U3BnRlQxdWRBVFFZd3VYdC82aQo1WmJ1VGpBekpsL3l6SFpFbDVsb2VsYitwZ1hUQ3Izbk1OZm5vTHR2THZ5WTZJbWFTT1hPSXV5ZW9Nb082QXhSCnRQU1lFRTN2VlFvUjg3cXlhSG5XVENoRFBUZFR6V2tIZGFHVXFLUEZnVDY0UXVINUsrbHFXMWF3eWc5VFVCMkMKQWJwRlZVQlB4bkJ1ZGlNMlFjZXhuUFhPN0FpREpIYlNqd3V6VVFJREFRQUJBb0lCQVFDWGVDWWxiV1VFaGxvUgpWSmh6L2laWjh6Q0lvbEJVQ1pQUEFFbGNrZUMwVHF3aDlMdjEwVnV3YzVtSHlHY0lEcWpGYjRXZW92UXBVNUNjCkJNUGp5cFRzN1V2akJZSHpQTFhOT2V6SGZuNFE3aEYyOTZZQXVVd053NDNDRzlzRjZUZ05HNGc3Y0VEL283RWcKZk81WktwVGxiWVcxSzhSZHpnc0RuMFNqOTc3Q2o1ZEl0cVRhNkN6V3VWOHd2aFMvWXlRbW8vbXB4V0dYNzdWNQpGdGoweVJJd3NNSlR6Z29SUW55WFc2SEtYc09MeDBwZ3djUUMzck9IOENFM3U4UXBSRVhPV0Y0Q2d0d0d2bVdXCmNMSmhJRjV6L0llSm5jQlZrREZLVU5LOTErTVpaV2k5emRldmZ1S2NTYVBzaWdudEJPYTRaQVF2QnZFUHhGZzAKM1laR3ZNUEJBb0dCQU9TVjVtN3BWK3BCeFdjdUxYZitjdEs5VjNDbFhnSUFMdUNEV2Q5SFJrNjBVV0gxaGdQQQpkSlFtcExSRzlIVGF2MHFCYUZScWJNUkx2eFlubnhaMHpPSEgyRnVjNHB2ZFNuenJWTG96aitDc2k5VmlsU2hkClJVOG5PNVUvbUF6b2JCSWQ4UkoxUW9yWk41SithT3l3MWdDOW1OUW54Vm04c0wyT2xEc3V4Tm1KQW9HQkFNZTYKQU5uTnRTblVvMlRNR1liOWZzRGpvbnFhb3lsTWozZFk3S3k2UkU0T1JlcVpqUFprNG1TaDRPSG9FbG5TazB1bQp0Y1oxS21VQkxpeW9DaERocWtnR3p1MEw2L0lmQm5XZ2FFbHhEekxRQ0w2bGd1cUJ6ZXFvQjQrTVpzZDBSTVpOClpKdGhsNXEzdXJnY2MvWDhPR1k0TXFidlo4UWt5bWVXaDcxc1c4R0pBb0dBRW1tY3NTeHNuM3NDeXFmbWs3YlUKU3ZOamVyaG5WU1Bzb3JzUjN6RmZrWEZtNk13ZEttb3pPY2ZQRnBKc21Ja1NSWThjOTBmSFVSeUUzT1QrSkpIdAordlhkRUt3WGVOU2ZibWFLWWFGTG9wNWplU0hDd0FpYlQ1L3FaY0JFb0MyTW52ejRjVE11MC81aFFwU2FJUTZ4CmZrZkhhcmQxWnlBUzRJSCtvTEhJdTNrQ2dZRUFzTmUwNFNVTy81YlRoZkJodWZEQ1JyQkhzUjh5ME9LRk5UdDcKZEFVSmJjT2RqSGVoSkpsM0MzdDV6d3paRXNjc3ZKTkQ2QkRlRk1qU3haK1VLaFpsMjVpTHA4QWlqaU9DYUt3NwpLcXY4dFJVV2FSZkxyekIzendvd2g1M2RjMFV6a0JIK3ZzWE9vcU9EcEhrdEErVHJXemJ2UW5nLy9LQkd4eW0xCnpyY2ZGMkVDZ1lBQW5VaXhDVFdWaW42QzV3NzJVV1pObmR4R1BBb3NiVVN6VUdPcFdnNVVHSDB5MVBSR1huNHcKeG00dGtrZ2ZoQnNqTGZ3T1FWN0t0N2Z1Z1VSYmJPazJ0OUNHbTFsUXRURmVKRldOV2F6ZVFENEZBdHozZmFkdQpoUk1mZHBDMDZ4c1p0ZjlvNHFKbmwvNm9qMExIR1dqL3FJNjFpZy9qcHlNeW93Vmh1NEM0ZHc9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=
```