#!/bin/bash
export DISPLAY=:1

# Configuración: obtener el token y el usuario de las variables de entorno
GITLAB_CODEREVIEW_TOKEN=${GITLAB_CODEREVIEW_TOKEN}
GITLAB_CODEREVIEW_USER=${GITLAB_CODEREVIEW_USER}

wait_time=5
expire_time=1000

# Verificar si las variables de entorno están configuradas
if [[ -z "$GITLAB_CODEREVIEW_TOKEN" ]] || [[ -z "$GITLAB_CODEREVIEW_USER" ]]; then
  echo "Error: GITLAB_CODEREVIEW_TOKEN y GITLAB_CODEREVIEW_USER deben estar configuradas."
  exit 1
fi

# Realiza la solicitud a la API de GitLab para obtener las solicitudes de merge asignadas al usuario
response=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_CODEREVIEW_TOKEN" \
  "https://gitlab.com/api/v4/merge_requests?state=opened&reviewer_username=$GITLAB_CODEREVIEW_USER&scope=all")

#Verifica que la respuesta devuela valores
if [[ $(echo "$response" | jq '. | length') -gt 0 ]]; then

  if echo "$response" | jq -e 'type == "object" and has("error")' >/dev/null; then
    echo "Error en la solicitud: $(echo "$response" | jq '.error')"
    exit 1
  fi

  # Procesa y muestra los resultados, enviando notificaciones en Linux
  echo "Repositorios que requieren tu revisión de código:"
  echo "$response" | jq -c '.[] | {projectid: .project_id, mergeid: .iid, web_url: .web_url, title: .title, reviewers: [.reviewers[].name]}' |
    while IFS= read -r mr_info; do

      # Extrae los valores directamente desde jq
      me=$(echo "$mr_info" | jq -r '.reviewers[0]')

      IFS='/' read -ra parts <<<$(echo "$mr_info" | jq -r '.web_url')

      project=$(echo "${parts[4]}" | cut -d'.' -f1)
      project_id=$(echo "$mr_info" | jq -r '.projectid')
      merge_id=$(echo "$mr_info" | jq -r '.mergeid')
      mr_title=$(echo "$mr_info" | jq -r '.title')
      mr_url=$(echo "$mr_info" | jq -r '.web_url')

      #eval "export $(egrep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $LOGNAME gnome-session)/environ)"

      short_title="${mr_title:0:15}"  # Limitamos el título a 50 caracteres
      short_project="${project:0:15}" # Limitamos el proyecto a 30 caracteres

      aprove=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_CODEREVIEW_TOKEN" \
        "https://gitlab.com/api/v4/projects/$project_id/merge_requests/$merge_id/approvals")

      if [[ $(echo "$aprove" | jq '. | length') -gt 0 ]]; then

        if echo "$aprove" | jq -e 'type == "object" and has("error")' >/dev/null; then

          echo "Error en la solicitud: $(echo "$aprove" | jq '.error')"
          exit 1
        fi

        isaprove=$(echo "$aprove" | jq -r '.user_has_approved')

        if [ "$isaprove" = false ]; then
          notify-send --action='default=Ver' -a "Revisión Requerida" "Merge Request: $short_title en el Proyecto: $short_project" $mr_url -i /usr/local/bin/gitlab.ico --expire-time=$expire_time --urgency=critical
        fi

      fi
    done
fi
