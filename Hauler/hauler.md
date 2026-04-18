# Hauler Setup

- Ref: [FOUND HERE](https://docs.hauler.dev/docs/introduction/quickstart)

## Install process

```sh
# install latest release
curl -sfL https://get.hauler.dev | bash
```

## Pull Container Images (from anywhere)

Topics covered will be:

- Pulling an image one at a time
- Leveraging a image manifest (image list)
- Prep for airgapping

### Pulling an Image One At A Time

```sh
read -s PASSWORD
# enter your password and press 'enter'
hauler login <oci-endpoint> -u <username> -p $PASSWORD
# Example used is pulling an image from registry1.dso.mil (IronBank)
hauler store add image registry1.dso.mil/ironbank/sonarsource/sonarqube/sonarqube-community-build:25.10.0.114319-community
2025-10-23 12:22:03 INF adding image [registry1.dso.mil/ironbank/sonarsource/sonarqube/sonarqube-community-build:25.10.0.114319-community] to the store
2025-10-23 12:22:09 INF successfully added image [registry1.dso.mil/ironbank/sonarsource/sonarqube/sonarqube-community-build:25.10.0.114319-community]
hauler store list
+-----------------------------------------------------------------------------------------------------+-------+-------------+----------+---------+
| REFERENCE                                                                                           | TYPE  | PLATFORM    | # LAYERS | SIZE    |
+-----------------------------------------------------------------------------------------------------+-------+-------------+----------+---------+
| registry1.dso.mil/ironbank/sonarsource/sonarqube/sonarqube-community-build:25.10.0.114319-community | image | linux/amd64 |        4 | 1.0 GB  |
|                                                                                                     | atts  | -           |        5 | 26.4 MB |
|                                                                                                     | sigs  | -           |        1 | 290 B   |
+-----------------------------------------------------------------------------------------------------+-------+-------------+----------+---------+
|                                                                                                                              TOTAL   | 1.0 GB  |
+-----------------------------------------------------------------------------------------------------+-------+-------------+----------+---------+
```
