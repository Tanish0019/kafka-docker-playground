#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/../../scripts/utils.sh

verify_docker_and_memory

check_docker_compose_version
check_bash_version
set_profiles

ENABLE_DOCKER_COMPOSE_FILE_OVERRIDE=""
DOCKER_COMPOSE_FILE_OVERRIDE=$1
nb_connect_services=0
if [ -f "${DOCKER_COMPOSE_FILE_OVERRIDE}" ]
then
    ENABLE_DOCKER_COMPOSE_FILE_OVERRIDE="-f ${DOCKER_COMPOSE_FILE_OVERRIDE}"
    set +e
    nb_connect_services=$(egrep -c "connect[0-9]+:" ${DOCKER_COMPOSE_FILE_OVERRIDE})
    set -e
    check_arm64_support "${DIR}" "${DOCKER_COMPOSE_FILE_OVERRIDE}"
fi

docker compose -f ../../environment/plaintext/docker-compose.yml ${ENABLE_DOCKER_COMPOSE_FILE_OVERRIDE} build
docker compose -f ../../environment/plaintext/docker-compose.yml ${ENABLE_DOCKER_COMPOSE_FILE_OVERRIDE} down -v --remove-orphans
docker compose -f ../../environment/plaintext/docker-compose.yml ${ENABLE_DOCKER_COMPOSE_FILE_OVERRIDE} ${profile_control_center_command} ${profile_ksqldb_command} ${profile_rest_proxy_command} ${profile_grafana_command} ${profile_kcat_command} ${profile_conduktor_command} ${profile_sql_datagen_command} ${profile_connect_nodes_command} ${profile_kafka_nodes_command} ${profile_schema_registry_command} up -d
log "📝 To see the actual properties file, use cli command playground get-properties -c <container>"
command="source ${DIR}/../../scripts/utils.sh && docker compose -f ${DIR}/../../environment/plaintext/docker-compose.yml ${ENABLE_DOCKER_COMPOSE_FILE_OVERRIDE} ${profile_control_center_command} ${profile_ksqldb_command} ${profile_rest_proxy_command} ${profile_grafana_command} ${profile_kcat_command} ${profile_conduktor_command} ${profile_sql_datagen_command} ${profile_connect_nodes_command} ${profile_kafka_nodes_command} ${profile_schema_registry_command} up -d"
echo "$command" >> /tmp/playground-command
log "✨ If you modify a docker-compose file and want to re-create the container(s), run cli command playground container recreate"


if [ "$#" -ne 0 ]
then
    shift
fi
../../scripts/wait-for-connect-and-controlcenter.sh $@

display_jmx_info
