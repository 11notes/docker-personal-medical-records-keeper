![banner](https://github.com/11notes/defaults/blob/main/static/img/banner.png?raw=true)

# PERSONAL MEDICAL RECORDS KEEPER
![size](https://img.shields.io/docker/image-size/11notes/personal-medical-records-keeper/0.29.0?color=0eb305)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![version](https://img.shields.io/docker/v/11notes/personal-medical-records-keeper/0.29.0?color=eb7a09)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![pulls](https://img.shields.io/docker/pulls/11notes/personal-medical-records-keeper?color=2b75d6)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)[<img src="https://img.shields.io/github/issues/11notes/docker-PERSONAL MEDICAL RECORDS KEEPER?color=7842f5">](https://github.com/11notes/docker-PERSONAL MEDICAL RECORDS KEEPER/issues)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![swiss_made](https://img.shields.io/badge/Swiss_Made-FFFFFF?labelColor=FF0000&logo=data:image/svg%2bxml;base64,PHN2ZyB2ZXJzaW9uPSIxIiB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDMyIDMyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWN0IHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgZmlsbD0idHJhbnNwYXJlbnQiLz4KICA8cGF0aCBkPSJtMTMgNmg2djdoN3Y2aC03djdoLTZ2LTdoLTd2LTZoN3oiIGZpbGw9IiNmZmYiLz4KPC9zdmc+)

Run personal-medical-records-keeper rootless, distroless and secure by default!

# INTRODUCTION 📢

[personal-medical-records-keeper](https://github.com/afairgiant/Personal-Medical-Records-Keeper) (created by [traah](https://www.reddit.com/user/traah/)) is a lightweight, self-hosted application for managing your personal medical information. Keep your health records organized and accessible while maintaining complete control over your data privacy.

![DASHBOARD](https://github.com/11notes/docker-Personal Medical Records Keeper/blob/master/img/Dashboard.png?raw=true)

# SYNOPSIS 📖
**What can I do with this?** This image will give you a [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) and leightweight PERSONAL MEDICAL RECORDS KEEPER installation. Perfect to store your medical records as safe as possible.

# ARR STACK IMAGES 🏴‍☠️
This image is part of the so called arr-stack (apps to pirate and manage media content). Here is the list of all it's companion apps for the best pirate experience:

- [11notes/configarr](https://github.com/11notes/docker-configarr) - as your TRaSH guide syncer for Sonarr and Radarr
- [11notes/plex](https://github.com/11notes/docker-plex) - as your media server
- [11notes/prowlarr](https://github.com/11notes/docker-prowlarr) - to manage all your indexers
- [11notes/qbittorrent](https://github.com/11notes/docker-qbittorrent) - as your torrent client
- [11notes/radarr](https://github.com/11notes/docker-radarr) - to manage your films
- [11notes/sabnzbd](https://github.com/11notes/docker-sabnzbd) - as your usenet client
- [11notes/sonarr](https://github.com/11notes/docker-sonarr) - to manage your TV shows

# UNIQUE VALUE PROPOSITION 💶
**Why should I run this image and not the other image(s) that already exist?** Good question! Because ...

> [!IMPORTANT]
>* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
>* ... this image is auto updated to the latest version via CI/CD
>* ... this image is built and compiled from source
>* ... this image supports 32bit architecture
>* ... this image has a health check
>* ... this image runs read-only
>* ... this image is automatically scanned for CVEs before and after publishing
>* ... this image is created via a secure and pinned CI/CD process
>* ... this image is very small

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

# COMPARISON 🏁
Below you find a comparison between this image and the most used or original one.

| **image** | **size on disk** | **init default as** | **[distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)** | supported architectures
| ---: | ---: | :---: | :---: | :---: |
| afairgiant/personal-medical-records-keeper/medical-records | 333MB | 0:0 | ❌ | amd64, arm64 |

# VOLUMES 📁
* **/pmrk/var** - Directory of all your uploads
* **/pmrk/backup (optional)** - Directory of your backups

# COMPOSE ✂️
```yaml
name: "medical"

x-lockdown: &lockdown
  # prevents write access to the image itself
  read_only: true
  # prevents any process within the container to gain more privileges
  security_opt:
    - "no-new-privileges=true"

services:
  postgres:
    # for more information about this image checkout:
    # https://github.com/11notes/docker-postgres
    image: "11notes/postgres:16"
    <<: *lockdown
    environment:
      TZ: "Europe/Zurich"
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_BACKUP_SCHEDULE: "0 3 * * *"
    networks:
      backend:
    volumes:
      - "postgres.etc:/postgres/etc"
      - "postgres.var:/postgres/var"
      - "postgres.backup:/postgres/backup"
    tmpfs:
      - "/postgres/run:uid=1000,gid=1000"
      - "/postgres/log:uid=1000,gid=1000"
    restart: "always"

  pmrk:
    depends_on:
      postgres:
        condition: "service_healthy"
        restart: true
    image: "11notes/personal-medical-records-keeper:0.29.0"
    <<: *lockdown
    environment:
      TZ: "Europe/Zurich"
      DB_PASSWORD: ${POSTGRES_PASSWORD}
      SECRET_KEY: ${SECRET_KEY}
    ports:
      - "3000:8080/tcp"
    networks:
      frontend:
      backend:
    volumes:
      - "pmrk.var:/pmrk/var"
      - "pmrk.backup:/pmrk/backup"
    tmpfs:
      - "/pmrk/log:uid=1000,gid=1000"
    restart: "always"

volumes:
  postgres.etc:
  postgres.var:
  postgres.backup:
  pmrk.var:
  pmrk.backup:

networks:
  frontend:
  backend:
    internal: true
```
To find out how you can change the default UID/GID of this container image, consult the [how-to.changeUIDGID](https://github.com/11notes/RTFM/blob/main/linux/container/image/11notes/how-to.changeUIDGID.md#change-uidgid-the-correct-way) section of my [RTFM](https://github.com/11notes/RTFM)

# DEFAULT SETTINGS 🗃️
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user name |
| `uid` | 1000 | [user identifier](https://en.wikipedia.org/wiki/User_identifier) |
| `gid` | 1000 | [group identifier](https://en.wikipedia.org/wiki/Group_identifier) |
| `home` | /pmrk | home directory of user docker |

# ENVIRONMENT 📝
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Will activate debug option for container image and app (if available) | |

# MAIN TAGS 🏷️
These are the main tags for the image. There is also a tag for each commit and its shorthand sha256 value.

* [0.29.0](https://hub.docker.com/r/11notes/Personal Medical Records Keeper/tags?name=0.29.0)

### There is no latest tag, what am I supposed to do about updates?
It is of my opinion that the ```:latest``` tag is dangerous. Many times, I’ve introduced **breaking** changes to my images. This would have messed up everything for some people. If you don’t want to change the tag to the latest [semver](https://semver.org/), simply use the short versions of [semver](https://semver.org/). Instead of using ```:0.29.0``` you can use ```:0``` or ```:0.29```. Since on each new version these tags are updated to the latest version of the software, using them is identical to using ```:latest``` but at least fixed to a major or minor version.

If you still insist on having the bleeding edge release of this app, simply use the ```:rolling``` tag, but be warned! You will get the latest version of the app instantly, regardless of breaking changes or security issues or what so ever. You do this at your own risk!

# REGISTRIES ☁️
```
docker pull 11notes/personal-medical-records-keeper:0.29.0
docker pull ghcr.io/11notes/personal-medical-records-keeper:0.29.0
docker pull quay.io/11notes/personal-medical-records-keeper:0.29.0
```

# SOURCE 💾
* [11notes/personal-medical-records-keeper](https://github.com/11notes/docker-PERSONAL MEDICAL RECORDS KEEPER)

# PARENT IMAGE 🏛️
* [${{ json_readme_parent_image }}](${{ json_readme_parent_url }})

# BUILT WITH 🧰
* [afairgiant/personal-medical-records-keeper](https://github.com/afairgiant/Personal-Medical-Records-Keeper)
* [11notes/util](https://github.com/11notes/docker-util)

# GENERAL TIPS 📌
> [!TIP]
>* Use a reverse proxy like Traefik, Nginx, HAproxy to terminate TLS and to protect your endpoints
>* Use Let’s Encrypt DNS-01 challenge to obtain valid SSL certificates for your services

# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-Personal Medical Records Keeper/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-Personal Medical Records Keeper/issues), thanks. If you have a question or inputs please create a new [discussion](https://github.com/11notes/docker-Personal Medical Records Keeper/discussions) instead of an issue. You can find all my other repositories on [github](https://github.com/11notes?tab=repositories).

*created 25.09.2025, 17:30:26 (CET)*