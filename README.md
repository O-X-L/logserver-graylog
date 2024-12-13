# Graylog Open Setup

This guide covers a single-node setup of [Graylog Open](https://graylog.org/products/source-available/) by utilizing `docker compose`.

You can also install the Graylog stack without using docker. The most important config files are the same.

<a href="https://graylog.org/products/source-available/">
  <img src="https://raw.githubusercontent.com/O-X-L/logserver-graylog/refs/heads/main/Overview.png" alt="Graylog Stack" width="350px"/>
</a>

## Setup Guide

This guide works on a clean [Debian netinstall](https://www.debian.org/CD/netinst/) installation.

----

### 1. Disk

Make sure to use a dedicated partition (*LVM*) or a dedicated virtual-disk if ran as VM mounted at `/usr/share/opensearch` to save the log-data to.

If you want/need to create index-snapshots - you might also want to use a dedicated one mounted at `/usr/share/opensearch/backup`.

----

### 2. Setup docker

[Docker Docs](https://docs.docker.com/engine/install/debian/#install-using-the-repository)

```bash
sudo -i
apt-get update
apt-get install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

----

### 3. Main config files

`mkdir /etc/graylog`

Place files into `/etc/graylog`:

   * [docker-compose.yml](https://github.com/O-X-L/logserver-graylog/blob/main/config/docker-compose.yml) => update the `OPENSEARCH_INITIAL_ADMIN_PASSWORD`
   * [Dockerfile_mongodb](https://github.com/O-X-L/logserver-graylog/blob/main/config/Dockerfile_mongodb)
   * [Dockerfile_opensearch](https://github.com/O-X-L/logserver-graylog/blob/main/config/Dockerfile_opensearch)
   * [Dockerfile_nginx](https://github.com/O-X-L/logserver-graylog/blob/main/config/Dockerfile_nginx)
   * [nginx.conf](https://github.com/O-X-L/logserver-graylog/blob/main/config/nginx.conf)
   * [Dockerfile_pki](https://github.com/O-X-L/logserver-graylog/blob/main/config/Dockerfile_pki)

----

### 4. Create service-users

This is necessary for persistent data storage to work correctly.

```bash
groupadd graylog --gid 1100
useradd --shell /usr/sbin/nologin --uid 1100 --gid 1100 graylog
groupadd mongodb --gid 1101
useradd --shell /usr/sbin/nologin --uid 1101 --gid 1101 mongodb
groupadd opensearch --gid 1102
useradd --shell /usr/sbin/nologin --uid 1102 --gid 1102 opensearch
```

----

### 5. Create directories

```bash
mkdir -p /usr/share/graylog/data /usr/share/graylog/data/config /usr/share/graylog/data/ssl
chown -R graylog:graylog /usr/share/graylog
mkdir -p /usr/share/opensearch/config /usr/share/opensearch/data
chown -R opensearch:opensearch /usr/share/opensearch
mkdir -p /usr/share/mongodb
chown -R mongodb:mongodb /usr/share/mongodb
mkdir -p /usr/share/log-pki
chmod 700 /usr/share/log-pki
```

----

### 6. Application config-files

**OpenSearch**:
* `ln -s /usr/share/opensearch/config /etc/graylog/opensearch`
* Place the opensearch config files into `/etc/graylog/opensearch`
  * [jvm.options](https://github.com/O-X-L/logserver-graylog/blob/main/config/opensearch/jvm.options) => update the GB of RAM to use: `-Xms` and `-Xmx`
  * [log4j2.properties](https://github.com/O-X-L/logserver-graylog/blob/main/config/opensearch/log4j2.properties)
  * [opensearch.yml](https://github.com/O-X-L/logserver-graylog/blob/main/config/opensearch/opensearch.yml)

**Graylog**:
* `ln -s /usr/share/graylog/data/config /etc/graylog/server`
* Place graylog config file into `/etc/graylog/server`
  * [graylog.conf](https://github.com/O-X-L/logserver-graylog/blob/main/config/server/graylog.conf)
    * Add a long `password_secret`
    * Generate graylog admin-hash and add it to the config as `root_password_sha2`: `echo 'PASSWORD' | tr -d '\n' | sha256sum | cut -d " " -f1`

----

### 7. Start it

`docker compose -f "/etc/graylog/docker-compose.yml" up -d`

----

### 8. Check

Logs: `docker logs -f log-graylog`

Status: `docker ps -a`

----

### 9. OpenSearch Settings

Set [OpenSearch Cluster-Settings](https://opensearch.org/docs/2.2/api-reference/cluster-api/cluster-settings/):

After the opensearch cluster is online - we need to configure its watermark:

```bash
curl -XPUT "http://localhost:9200/_cluster/settings" -H 'Content-Type: application/json' -d'
{
  "persistent":{
    "cluster.routing.allocation.disk.watermark.low": "95%",
    "cluster.routing.allocation.disk.watermark.high": "98%",
    "cluster.routing.allocation.disk.watermark.flood_stage": "99%"
  }
}
'
```

----

## Troubleshooting

1. Check the status of the containers: `docker ps -a`

2. Read logs of the containers: `docker logs -f log-<COMPONENT>`

3. Check networking:

```bash
apt install net-tools
netstat -tulpn
```

----

## Certificates

The `log-pki` (*Public-Key-Infrastructure*) container can be used to generate certificates that are needed for encrypted log-forwarding.

### Server

Generate the certificate:

```bash
CMD="/pki/pki.sh --no-text --batch --subject-alt-name='DNS:logserver.intern,IP:192.168.0.10' build-server-full logserver nopass"
docker run --rm -v /usr/share/log-pki:/pki/pki -it local/pki $CMD
```

Copy the key/cert pair to a directory graylog can read:

```bash
cp /usr/share/log-pki/ca.crt /usr/share/graylog/data/ssl/
cp /usr/share/log-pki/issued/logserver.crt /usr/share/graylog/data/ssl/
cp /usr/share/log-pki/issued/logserver.nopw.key /usr/share/graylog/data/ssl/
chmod 400 /usr/share/graylog/data/ssl/*
chown graylog /usr/share/graylog/data/ssl/*
```

Then you can use it for your inputs.

----

### Client

Generate the certificate:

```bash
CMD="/pki/pki.sh --no-text --batch build-client-full <NAME> nopass"
docker run --rm -v /usr/share/log-pki:/pki/pki -it local/pki $CMD
```

Then move the files to your client-system:

* `/usr/share/log-pki/ca.crt`
* `/usr/share/log-pki/issued/<NAME>.crt`
* `/usr/share/log-pki/private/<NAME>.nopw.key`

Make sure your client validates the server-certificate by the provided `ca.crt`!

----

### Renewal

Remove an existing certificate:

```bash
CMD='/pki/pki.sh --batch --no-text revoke <NAME>'
docker run --rm -v /usr/share/log-pki:/pki/pki -it local/pki $CMD
```

Then simply re-generate it as seen above.

----

# Update

### 1. Major Upgrade

If you want to perform a major upgrade - change version numbers in:
* `docker-compose.yml`
* `Dockerfile_mongodb`
* `Dockerfile_opensearch`


### 2. Stop the containers

`docker compose -f "/etc/graylog/docker-compose.yml" down`

### 3. Remove the old images

Replace VERSION by the current one: `docker image ls`

```bash
docker image rm "local/opensearch:<VERSION>"
docker image rm "local/mongodb:<VERSION>"
docker image rm "local/nginx:latest"
docker image prune -f
```

### 4. Update the images

```bash
docker compose -f "/etc/graylog/docker-compose.yml" build
docker compose -f "/etc/graylog/docker-compose.yml" pull --quiet --ignore-pull-failures
```

### 5. Start it

`docker compose -f "/etc/graylog/docker-compose.yml" up -d`
