FROM hasura/graphql-engine:v2.34.0-beta.1-ce.cli-migrations-v3

COPY ./metadata /project/metadata
COPY ./migrations /project/migrations

ENV HASURA_GRAPHQL_METADATA_DIR="/project/metadata"
ENV HASURA_GRAPHQL_MIGRATIONS_DIR="/project/migrations"
ENV HASURA_GRAPHQL_ENABLE_REMOTE_SCHEMA_PERMISSIONS="true"

EXPOSE 8080