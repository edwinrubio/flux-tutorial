

```markdown
# Conceptos basicos de flux
[Documentación de Flux](https://fluxcd.io/flux/components/)

# Comandos de instalación
[Instalación de Flux](https://fluxcd.io/flux/installation/)

# Formas de estructurar tus repositorios
[Estructuración de Repositorios](https://fluxcd.io/flux/guides/repository-structure/)

# Generar el token para poder entrar a GitHub desde Flux
1. Visita [GitHub Tokens](https://github.com/settings/tokens)
2. Ejecuta los siguientes comandos:
   ```bash
   export GITHUB_TOKEN=<tu-token>
   export GITHUB_USER=<tu-usuario>
   ```

# Habilitar el cluster de Kubernetes
Ejecuta el siguiente comando:
```bash
flux check --pre
```

# Esto crea un repositorio de flux en tu cuenta
1. Ahi encontraras los archivos de instalacion basicos de Flux
2. Y la carpeta ./clusters/my-cluster en donde haremos toda la magia
```bash
flux bootstrap github \
  --components-extra=image-reflector-controller,image-automation-controller \
  --owner=$GITHUB_USER \
  --repository=fleet-infra \
  --branch=main \
  --path=./clusters/my-cluster \
  --personal

git clone https://github.com/$GITHUB_USER/fleet-infra
cd fleet-infra
```

# Crear recurso para mapear el repositorio donde estan todos los recursos que vamos a usar
```bash
flux create source git podinfo \
  --url=https://github.com/stefanprodan/podinfo \
  --branch=master \
  --interval=1m \
  --export > ./clusters/my-cluster/git/podinfo-source.yaml
```

# Crear kustomization para desplegar el directorio
```bash
flux create kustomization podinfo \
  --target-namespace=default \
  --source=podinfo \
  --path="./kustomize" \
  --prune=true \
  --wait=true \
  --interval=5m \
  --retry-interval=2m \
  --health-check-timeout=3m \
  --export > ./clusters/my-cluster/podinfo-kustomization.yaml
```

# Comando para aplicar los cambios que estan en el repositorio
```bash
flux reconcile kustomization flux-system --with-source
```

# Comando para suspender las actualizaciones
```bash
flux suspend kustomization <nombre>
```

# Despliegues con Helm
- Explicación del archivo `repository` que esta en el repo
- Explicación del archivo `release` que esta en el repo

# Despliegues desde un Registry
1. Crear deployment
2. Crear archivo `registry`
```bash
flux create image repository podinfo \
--image=ghcr.io/stefanprodan/podinfo \
--interval=5m \
--export > ./clusters/my-cluster/podinfo-registry.yaml
```

3. Crear archivo `policy`
```bash
flux create image policy podinfo \
--image-ref=podinfo \
--select-semver=5.0.x \
--export > ./clusters/my-cluster/podinfo-policy.yaml
```

4. Subir cambios y sincronizar con Flux
```bash
flux reconcile kustomization flux-system --with-source
```

# Ver versiones disponibles de imágenes
```bash
kubectl -n flux-system describe imagerepositories podinfo
```

# Crear archivo `automation`
```bash
flux create image update flux-system \
--interval=30m \
--git-repo-ref=flux-system \
--git-repo-path="./clusters/my-cluster" \
--checkout-branch=main \
--push-branch=main \
--author-name=fluxcdbot \
--author-email=fluxcdbot@users.noreply.github.com \
--commit-template="{{range .Updated.Images}}{{println .}}{{end}}" \
--export > ./clusters/my-cluster/flux-system-automation.yaml
```

# Agregar comentario en el deployment para aplicar políticas
```json
# {"$imagepolicy": "flux-system:podinfo"}
```

# Subir cambios y listo
```bash
flux reconcile kustomization flux-system --with-source
```
