# testeo_sonarqube
Repositorio de prueba para sonarqube con github actions

## Arquitectura de Infraestructura (IaC con Terraform)

Este proyecto utiliza Terraform para gestionar la infraestructura como código (IaC) en Google Cloud Platform.

### Prerrequisitos

1.  **Google Cloud SDK (`gcloud`)**: [Instrucciones de instalación](https://cloud.google.com/sdk/docs/install).
2.  **Terraform**: [Instrucciones de instalación](https://learn.hashicorp.com/tutorials/terraform/install-cli).
3.  **Autenticación**: Autentícate con GCP:
    ```bash
    gcloud auth application-default login
    ```

### Estructura de Carpetas

-   `infra/`: Contiene todo el código de Terraform.
    -   `main.tf`: Archivo principal que orquesta los módulos.
    -   `variables.tf`: Variables de entrada para la configuración.
    -   `terraform.tfvars.example`: Archivo de ejemplo para las variables.
    -   `modules/`: Módulos reutilizables para cada componente de GCP (GCS, Cloud SQL, etc.).
-   `db/`: Contiene scripts de migración de la base de datos.
-   `functions/`: Contiene el código fuente de las Cloud Functions.

### Despliegue de la Infraestructura

1.  **Navegar al directorio de infraestructura**:
    ```bash
    cd infra
    ```

2.  **Crear archivo de variables**:
    Copia el archivo de ejemplo y edítalo con los valores de tu proyecto.
    ```bash
    cp terraform.tfvars.example terraform.tfvars
    ```
    Edita `terraform.tfvars` y establece tu `project_id` y `db_password`.

3.  **Inicializar Terraform**:
    Descarga los proveedores necesarios.
    ```bash
    terraform init
    ```

4.  **Planificar los cambios**:
    Revisa los recursos que Terraform creará.
    ```bash
    terraform plan
    ```

5.  **Aplicar los cambios**:
    Aprovisiona la infraestructura en GCP. Confirma con `yes` cuando se te solicite.
    ```bash
    terraform apply
    ```

### Despliegue de la Base de Datos

Una vez que la instancia de Cloud SQL esté creada, puedes aplicar las migraciones.

1.  **Conectarse a la instancia de Cloud SQL**:
    La forma más sencilla es usar el [Cloud SQL Auth Proxy](https://cloud.google.com/sql/docs/postgres/connect-auth-proxy).
    ```bash
    # Reemplaza INSTANCE_CONNECTION_NAME con la salida de 'terraform output -raw instance_connection_name'
    ./cloud-sql-proxy INSTANCE_CONNECTION_NAME
    ```

2.  **Ejecutar la migración**:
    Con el proxy en ejecución en otra terminal, usa `psql` para ejecutar el script de migración.
    ```bash
    psql "host=127.0.0.1 port=5432 sslmode=disable dbname=user_management_db user=auth_service_user" < ../db/migrations/001_create_users_table.sql
    ```
    Se te pedirá la contraseña de la base de datos que definiste en `terraform.tfvars`.

### Destruir la Infraestructura

Para eliminar todos los recursos creados por Terraform (¡cuidado, esto es destructivo!):
```bash
cd infra
terraform destroy
```
