# islandora-microservices

To use these services, in your ISLE `docker-compose.yml` you can point to the Cloud Run deployments to perform your derivative generation

```
    alpaca-prod: &alpaca-prod
        <<: [*prod, *alpaca]
        environment:
            ALPACA_DERIVATIVE_FITS_URL: https://CR_URL
            ALPACA_DERIVATIVE_HOMARUS_URL: https://CR_URL
            ALPACA_DERIVATIVE_HOUDINI_URL: https://CR_URL
            ALPACA_DERIVATIVE_OCR_URL: https://CR_URL
```
