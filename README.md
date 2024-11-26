# notify-reviewer-jobs

Este es un pequeño script para mostar notificaciones en linux por cada PR asignado al usuario de gitlab

## Configuración: 

Para configurar este script es necesario crear un cron para ejecutar este en un tiempo determinado y agregar las variables de tornos necesarias

### Variable de entorno: 

- GITLAB_CODEREVIEW_TOKEN ="token Gitlab"
- GITLAB_CODEREVIEW_USER ="user Gitlab"

### Cron:

crear una carpeta para almacenar el log del script(opcional)

*/5 8-17 * * *  XDG_RUNTIME_DIR=/run/user/$(id -u) /usr/local/bin/jenkinsreviwer.sh >> /usr/local/bin/logs/reviewer.log 2>&1
