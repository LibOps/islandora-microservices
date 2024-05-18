# islandora-microservices

Your Islandora instance can leverage [the Crayfish microservices](https://github.com/islandora/crayfish) running in the Cloud. 

## How it works

The microservices are running in multiple regions, and your microservice requests will route to the region closest to your Islandora server.

```mermaid
flowchart TD
    A[Alice] -->|Uploads TIFF image| B(Islandora Server\nin Indiana)
    B -- GET fa:fa-image derivative --> C{fa:fa-network-wired}
    C -.-|Nevada| G[imagefa:fa-magic-wand-sparkles]
    C -.-|Oregon| D[imagefa:fa-magic-wand-sparkles]
    C -.-|Iowa| E[imagefa:fa-magic-wand-sparkles]
    C -->|Ohio| F[imagefa:fa-magic-wand-sparkles]
    C -.-|Virginia| H[imagefa:fa-magic-wand-sparkles]
    F[imagefa:fa-magic-wand-sparkles]-- fa:fa-image derivative -->B
```

## Install

To use these services, in your ISLE `docker-compose.yml` you can point to the Cloud Run deployments to perform your derivative generation.

```
    alpaca-prod: &alpaca-prod
        <<: [*prod, *alpaca]
        environment:
            ALPACA_DERIVATIVE_FITS_URL: https://microservice.libops.site/crayfits
            ALPACA_DERIVATIVE_HOMARUS_URL: https://microservice.libops.site/homarus
            ALPACA_DERIVATIVE_HOUDINI_URL: https://microservice.libops.site/houdini
            ALPACA_DERIVATIVE_OCR_URL: https://microservice.libops.site/hypercube
```

Your files must be accessible over the WWW in order to use this.
