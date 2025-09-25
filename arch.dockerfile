# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_SRC=afairgiant/Personal-Medical-Records-Keeper.git \
      BUILD_ROOT=/Personal-Medical-Records-Keeper \
      PYTHON_VERSION=3.13

# :: FOREIGN IMAGES
  FROM 11notes/util:bin AS util-bin
  FROM 11notes/distroless:localhealth AS distroless-localhealth


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: PERSONAL-MEDICAL-RECORDS-KEEPER / SOURCE
  FROM 11notes/python:wheel-${PYTHON_VERSION} AS src
  ARG APP_VERSION \
      APP_ROOT \
      BUILD_SRC \
      BUILD_ROOT

  RUN set -ex; \
    eleven git clone ${BUILD_SRC} v${APP_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    pip install pur; \
    pur -r ./requirements.txt;

# :: PERSONAL-MEDICAL-RECORDS-KEEPER / FRONTEND
  FROM node:lts-alpine AS frontend
  ARG BUILD_ROOT
  COPY --from=src ${BUILD_ROOT} ${BUILD_ROOT}
  ENV NODE_ENV=production \
      REACT_APP_API_URL=/api/v1 \
      CI=true \
      GENERATE_SOURCEMAP=false

  RUN set -ex; \
    apk --update --no-cache add \
      pnpm;

  RUN set -ex; \
    cd ${BUILD_ROOT}/frontend; \
    pnpm install; \
    find . -name "*.test.js" -o -name "*.test.jsx" -o -name "*.spec.js" -o -name "*.spec.jsx" | xargs rm -f; \
    rm -rf src/__tests__ src/**/__tests__; \
    CI=false ESLINT_NO_DEV_ERRORS=true DISABLE_ESLINT_PLUGIN=true pnpm run build; \
    find build -name "*.map" -delete; \
    pnpm prune --production;

# :: PERSONAL-MEDICAL-RECORDS-KEEPER / WHEELS
  FROM 11notes/python:wheel-${PYTHON_VERSION} AS wheels
  ARG BUILD_ROOT
  COPY --from=src ${BUILD_ROOT}/requirements.txt /
  USER root
  RUN set -ex; \
    mkdir -p /pip/wheels; \
    pip wheel \
      --wheel-dir /pip/wheels \
      -f https://11notes.github.io/python-wheels/ \
      -r /requirements.txt;

# :: PERSONAL-MEDICAL-RECORDS-KEEPER / BACKEND
  FROM 11notes/python:${PYTHON_VERSION} AS build
  USER root
  ARG APP_ROOT \
      BUILD_ROOT
  COPY --from=frontend ${BUILD_ROOT}/frontend/build/ /opt${APP_ROOT}/static
  COPY --from=src ${BUILD_ROOT}/app /opt${APP_ROOT}/app
  COPY --from=src ${BUILD_ROOT}/run.py /opt${APP_ROOT}
  COPY --from=src ${BUILD_ROOT}/alembic /opt${APP_ROOT}/alembic
  COPY --from=wheels /pip/wheels /pip/wheels
  COPY --from=src ${BUILD_ROOT}/requirements.txt /

  RUN set -ex; \
    pip install \
      --no-index \
      -f /pip/wheels \
      -f https://11notes.github.io/python-wheels/ \
      -r /requirements.txt; \
    rm -rf /pip/wheels; \
    rm -f /requirements.txt;

  RUN set -ex; \
    chmod -R 0755 /opt${APP_ROOT};

  RUN set -ex; \
    apk --update --no-cache add \
      libgcc \
      libpq \
      libjpeg-turbo;

# :: FILE-SYSTEM
  FROM alpine AS file-system
  ARG APP_ROOT
  RUN set -ex; \
    mkdir -p /distroless${APP_ROOT}/var; \
    mkdir -p /distroless${APP_ROOT}/log; \
    mkdir -p /distroless${APP_ROOT}/backup;


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
# :: HEADER
  FROM scratch

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
        APP_NAME=${APP_NAME} \
        APP_VERSION=${APP_VERSION} \
        APP_ROOT=${APP_ROOT}

  # :: app specific environment
    ENV DB_HOST="postgres" \
        DB_PORT="5432" \
        DB_NAME="postgres" \
        DB_USER="postgres" \
        STATIC_DIR="/opt${APP_ROOT}/static" \
        UPLOAD_DIR=${APP_ROOT}/var/uploads \
        TRASH_DIR=${APP_ROOT}/var/uploads/trash \
        BACKUP_DIR=${APP_ROOT}/backup \
        LOG_DIR=${APP_ROOT}/log \
        LOG_ROTATION_METHOD="python" \
        LOG_ROTATION_BACKUP_COUNT="1"

  # :: multi-stage
    COPY --from=build / /
    COPY --from=distroless-localhealth / /
    COPY --from=file-system --chown=${APP_UID}:${APP_GID} /distroless/ /

# :: PERSISTENT DATA
  VOLUME ["${APP_ROOT}/var","${APP_ROOT}/backup"]

# :: MONITORING
  HEALTHCHECK --interval=5s --timeout=2s --start-period=5s \
    CMD ["/usr/local/bin/localhealth", "http://127.0.0.1:8080/health"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/uvicorn"]
  WORKDIR /opt${APP_ROOT}
  CMD ["app.main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "1", "--log-level", "warning"]