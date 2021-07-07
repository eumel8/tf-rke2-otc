tf-rke2-otc
===========

Install Rancher on top of RKE2 on OTC with Terraform

Deploy [RKE2](https://rke2.io) with Terraform on Open Telekom Cloud (OTC)
with the following resources:

* VPC
* Subnet
* Security Groups
* ELB
* ECS (3 master nodes Ubuntu 20.04)
* EVS
* DNS (existing zone can be import with `terraform import opentelekomcloud_dns_zone_v2.dns <zone_id>`

Interested in [K3S](https://k2s.io) on OTC? Refer to the [tf-k3s-otc repo](https://github.com/eumel8/tf-k3s-otc) with
a full deployment of Kubernetes Cluster with K3S backend. This deployment here has an etcd instead RDS as data backend.

Rancher:
--------

Rancher app will installed with LetsEncrypt cert under the configured hostname. 

You can reach the service under https://hostname.domain

Prerequistes:
-------------

* Install Terraform CLI (v0.13.2+):

```
curl -o terraform.zip https://releases.hashicorp.com/terraform/0.13.2/terraform_0.13.2_linux_amd64.zip
unzip terraform
sudo mv terraform /usr/local/bin/
rm terraform.zip
```

* Switch to s3 folder and create a `terraform.tfvars` file for Terraform state S3 backend

```
bucket_name = <otc bucket name> # must be uniq
access_key  = <otc access key>
secret_key  = <otc secret key>
```

Deployment S3 backend:
----------------------

```
terraform init
terraform plan
terraform apply -auto-approve
```

* Create a `terraform.tfvars` file in the main folder

```
environment           = <environment name>    # e.g. "rke2-test"
rancher_host          = <rancher host name>   # e.g. "rke2"
rancher_domain        = <rancher domain name> # e.g. "otc.mcsps.de"
admin_email           = <admin email address for DNS/LetsEncrypt> # e.g. "nobody@telekom.de"
rke2_version          = <rke2 version> # e.g. v1.20.7+rke2r2
access_key            = <otc access key>
secret_key            = <otc secret key>
public_key            = <public ssh key vor ECS>
```

* Adapt `bucket` name in `backend.tf` with the bucket name which you created before

Deployment main app:
--------------------

```
export S3_ACCESS_KEY=<otc access key>
export S3_SECRET_KEY=<otc secret key>
export TF_VAR_environment=<your rke2 deployment>

terraform init -backend-config="access_key=$S3_ACCESS_KEY" -backend-config="secret_key=$S3_SECRET_KEY" -backend-config="key=${TF_VAR_environment}.tfstate"

terraform plan
terraform apply
```

Upgrades:
---------

It's possible to change the `rke2_version` variable and apply again with Terraform.
All VMs will be replaced because of the changed data content. Information are stored
in the etcd on an extra volume, so ground work should work out.


Rancher can upgrade manually:

```
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update
helm -n cattle-system upgrade -i rancher rancher-latest/rancher
  --set hostname=rancher.example.com \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=nobody@example.com \
  --set letsEncrypt.ingress.class=traefik \
  --set replicas=2 \
  --version v2.5.6 
```

Note: Rancher upgrade via Rancher API will often fail due the Rancher pod restarts during upgrade

Cert-Manager as well:

```
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm -n cert-manager upgrade -i cert-manager jetstack/cert-manager \
    --version v1.2.0
```

OS-Upgrade (i.e. Kernel/new image) can be done in the following way:

```
terraform taint opentelekomcloud_compute_instance_v2.rke2-server-1
terraform plan
```

This will replace rke2-server-1 with a new instance.

Note: this will also upgrade/downgrade the defined version of Rancher and Cert-Manager


Shutdown-Mode
-------------

Since Version 1.23.6 Terraform Open Telekom Cloud can handle ECS instance power state.

Shutoff:

```
terraform apply -auto-approve --var power_state=shutoff
```

Active:

```
terraform apply -auto-approve --var power_state=active
```

Retirement:
-----------

```
terraform destroy
```

Wireguard:
----------

In this deployment model there is no access with ssh to the nodes.
We can extend the deployment with a [Wireguard](https://www.wireguard.com) service
to create a vpn tunnel to access the internal network. There are multiple [clients](https://www.wireguard.com/install/)
(also for Windows).

At first it's required to install wireguard-tools and generate a keypair
for the Wireguard server:

```
sudo apt install -y wireguard-dkms wireguard-tools
wg genkey | tee privatekey | wg pubkey > publickey
```

Activate Wireguard deployment and put the content of the generated key
into terraform.tfvars:

```
deploy_wireguard      = "true"
wg_server_public_key  = "8EPWNuwv5vldRuLX4RNds/U78a8g2kTctNHRBClHTC4="
wg_server_private_key = "cNyppGTX8gwWLTRxxrNYfiRqTEjJSCMlBT+TbcEGAl8="
wg_peer_public_key    = "9tjOb+VA7vCHQj2rcOBSln8U7tVXzeEoBITYVuq1LFw="
```

Repeat key generating with the commands above or with the Wireguard client.
Add the public key into terraform.tfvars:

```
wg_peer_public_key = "9tjOb+VA7vCHQj2rcOBSln8U7tVXzeEoBITYVuq1LFw="
```

Deploy with `terraform plan` & `terraform apply`

Client configuration example:

```
[Interface]
PrivateKey = 0ITNzekaBeanMGefS7iyS2hsgzGK50GOpF6NKHoPPwF8=
ListenPort = 51820
Address    = 10.2.0.2/24

[Peer]
PublicKey  = 3dgEPWNuwv5vldRuLX4RNdshsg78a8g2kTctNHRBClHTC4=
AllowedIPs = 10.2.0.1/32, 10.1.0.0/24, 80.158.6.126/32
Endpoint   = 80.158.6.126:51820
```

* 10.2.0.1: Wireguard Server IP
* 10.2.0.2: Wireguard Client IP
* 10.1.0.0: Internal K3S Network
* 80.158.6.128: Floating IP of Wireguard Server

Windows user needs a manual route:

```
route add 10.1.0.0/24 mask 255.255.255.0 10.2.0.1
```

Debug:
------

Installation take a while (10-15 min). If no service is reachable you can login
to the first ECS instance. Most of the things should happen there in cloud-init:

```
ssh ubuntu@10.1.0.158
$ sudo su -
# tail /var/log/cloud-init-output.log
```

Check rke2 is running:

```
root@rke2-server-1:~# systemctl status rke2.service
● rke2.service - Lightweight Kubernetes
     Loaded: loaded (/etc/systemd/system/rke2.service; enabled; vendor preset: enabled)
     Active: active (running) since Fri 2020-09-18 14:48:42 UTC; 11min ago
```

Check Kubernetes is working:

```
# kubectl get nodes
NAME                 STATUS   ROLES                       AGE   VERSION
rke2-test-server-1   Ready    control-plane,etcd,master   21h   v1.20.7+rke2r2
rke2-test-server-2   Ready    control-plane,etcd,master   21h   v1.20.7+rke2r2
rke2-test-server-3   Ready    control-plane,etcd,master   21h   v1.20.7+rke2r2

# kubectl get pods -A
NAMESPACE                 NAME                                                 READY   STATUS      RESTARTS   AGE
cattle-system             rancher-78d6fc9df7-92j7x                             2/2     Running     0          21h
cattle-system             rancher-78d6fc9df7-bfk2s                             2/2     Running     0          21h
cattle-system             rancher-78d6fc9df7-wdnck                             2/2     Running     0          21h
cattle-system             rancher-webhook-686b44f6c8-psj6h                     1/1     Running     0          21h
cert-manager              cert-manager-7998c69865-kvltb                        1/1     Running     0          21h
cert-manager              cert-manager-cainjector-7b744d56fb-wv7nl             1/1     Running     0          21h
cert-manager              cert-manager-webhook-7d6d4c78bc-d52ds                1/1     Running     0          21h
fleet-system              fleet-agent-6d998b97f4-7vl8q                         1/1     Running     0          21h
fleet-system              fleet-controller-5799cd4887-ksvnk                    1/1     Running     0          21h
fleet-system              gitjob-5b4697d849-tgjt9                              1/1     Running     0          21h
kube-system               etcd-rke2-test-server-1                              1/1     Running     0          21h
kube-system               etcd-rke2-test-server-2                              1/1     Running     0          21h
kube-system               etcd-rke2-test-server-3                              1/1     Running     0          21h
kube-system               helm-install-rke2-canal-6vstv                        0/1     Completed   0          21h
kube-system               helm-install-rke2-coredns-dh8qf                      0/1     Completed   0          21h
kube-system               helm-install-rke2-ingress-nginx-hbkz2                0/1     Completed   0          21h
kube-system               helm-install-rke2-kube-proxy-fnm5v                   0/1     Completed   0          21h
kube-system               helm-install-rke2-metrics-server-vrvc2               0/1     Completed   0          21h
kube-system               kube-apiserver-rke2-test-server-1                    1/1     Running     0          21h
kube-system               kube-apiserver-rke2-test-server-2                    1/1     Running     0          21h
kube-system               kube-apiserver-rke2-test-server-3                    1/1     Running     0          21h
kube-system               kube-controller-manager-rke2-test-server-1           1/1     Running     0          21h
kube-system               kube-controller-manager-rke2-test-server-2           1/1     Running     0          21h
kube-system               kube-controller-manager-rke2-test-server-3           1/1     Running     0          21h
kube-system               kube-proxy-584wp                                     1/1     Running     0          21h
kube-system               kube-proxy-dr78l                                     1/1     Running     0          21h
kube-system               kube-proxy-fs6ft                                     1/1     Running     0          21h
kube-system               kube-scheduler-rke2-test-server-1                    1/1     Running     0          21h
kube-system               kube-scheduler-rke2-test-server-2                    1/1     Running     0          21h
kube-system               kube-scheduler-rke2-test-server-3                    1/1     Running     0          21h
kube-system               rke2-canal-j5qmf                                     2/2     Running     0          21h
kube-system               rke2-canal-j85c2                                     2/2     Running     0          21h
kube-system               rke2-canal-xpqvw                                     2/2     Running     0          21h
kube-system               rke2-coredns-rke2-coredns-675b5596bc-nfdrs           1/1     Running     0          21h
kube-system               rke2-ingress-nginx-controller-54946dd48f-t8kwx       1/1     Running     0          21h
kube-system               rke2-ingress-nginx-default-backend-5795954f8-kf56q   1/1     Running     0          21h
kube-system               rke2-metrics-server-559dc47bd8-vctzw                 1/1     Running     0          21h
rancher-operator-system   rancher-operator-849c695cf7-tj82v                    1/1     Running     0          21h
```

Migration from RKE Cluster
--------------------------

The procedure is described in [Rancher docs](https://rancher.com/docs/rancher/v2.x/en/backups/v2.5/migrating-rancher/)

note: as mentioned Rancher version 2.5+ is needed.

working steps:

   * Upgrade Rancher 2.5+
   * Install [rancher-backup](https://rancher.com/docs/rancher/v2.x/en/backups/v2.5/#installing-rancher-backup-with-the-helm-cli)
   * Perform etcd backup
   * Perform S3 backup
   * Create Git Repo for new Raseed environment in a CI/CD pipeline
   * Shutdown old public endpoint (cluster agents of downstream cluster should disconnect)
   * Switch DNS entry of public endpoint (if no automation like external-dns is used)
   * Execute created CI/CD Pipeline for environment
   * Login into RancherUI of the new environment
   * Install rancher-backup
   * Restore S3 backup
   * Review downstream clusters


Credits:
-------

Frank Kloeker <f.kloeker@telekom.de>

Life is for sharing. If you have an issue with the code or want to improve it,
feel free to open an issue or an pull request.
