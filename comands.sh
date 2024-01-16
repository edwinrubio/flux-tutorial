#Conceptos basicos de flux
https://fluxcd.io/flux/components/

#install commands
https://fluxcd.io/flux/installation/

#formas de estructurar tus repositorios
https://fluxcd.io/flux/guides/repository-structure/

#Generar el token para poder entrar a github desde flux
https://github.com/settings/tokens
export GITHUB_TOKEN=<your-token>
export GITHUB_USER=<your-username>


#habilitar el cluster de kubernetes
#Ejecutar este comando
flux check --pre

#Esto crea un repositorio
flux bootstrap github \
  --components-extra=image-reflector-controller,image-automation-controller \
  --owner=$GITHUB_USER \
  --repository=fleet-infra \
  --branch=main \
  --path=./clusters/my-cluster \
  --personal

#Despues ejecutamos este comando para acceder al repo
git clone https://github.com/$GITHUB_USER/fleet-infra
cd fleet-infra

#Creamos este recurso que va a mapear el repo 
flux create source git podinfo \
  --url=https://github.com/stefanprodan/podinfo \
  --branch=master \
  --interval=1m \
  --export > ./clusters/my-cluster/git/podinfo-source.yaml

#Ejecutamos este comando para apuntar el directorio que queremos desplegar
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

#Comando para checkear el repo
flux reconcile kustomization flux-system --with-source

#Comando para suspender las actualizaciones
flux suspend kustomization <name>


#Como se hace con Helm

#Explicacion del archivo repository
#Explicacion del archivo realease


#COMO HACEMOS DESPLIEGUES DESDE UN REGISTRY

#Creamos nuestro deployment

#Creacion del archivo registry
flux create image repository podinfo \
--image=ghcr.io/stefanprodan/podinfo \
--interval=5m \
--export > ./clusters/my-cluster/podinfo-registry.yaml


#Creacion del archivo policy
flux create image policy podinfo \
--image-ref=podinfo \
--select-semver=5.0.x \
--export > ./clusters/my-cluster/podinfo-policy.yaml

#subir los cambios
#sincronizar con flux
flux reconcile kustomization flux-system --with-source

#Comando para ver las versiones disponibles de imagenes 
kubectl -n flux-system describe imagerepositories podinfo


#Ejecutar este comando para crear el archivo automation
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


#Agregar este comment en el deployment:image para que se apliquen las politicas
 # {"$imagepolicy": "flux-system:podinfo"}

#subir cambios y listo
flux reconcile kustomization flux-system --with-source



