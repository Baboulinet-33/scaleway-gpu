# POC GPU

Ce poc permet de configurer l'opérateur nvidia pour les GPU (notamment H100) afin de pouvoir découper le GPU en plusieurs instances.

Pour cela 2 techniques sont à notre disposition (possibilité de mixer les 2 techniques pour un découpage fin):

- MIG (MultiInstance GPU): permet un découpage physique d'une carte en plusieurs cartes distinctes
- Time Slicing: permet de découper une carte en sous unité temporelle (permet d'avoir toutes les ressources de la carte pour un temps donné)

## Installation

Sans objet, fait automatiquement lors de la commande d'un pool GPU sur scaleway

## Configuration

**Il ne doit pas y avoir de travaux en cours sur la carte, sinon le changement de configuration ne se fera pas.**

### MIG

Il est possible d'adopter plusieurs stratégies pour le MIG:

- single: découpage de la carte en instance égale (par ex. un H100 de 80Go découpé en 4 H100 de 20Go)
- mixed: permet un découpage plus fin (par ex. un H100 de 80Go découpé de la forme suivante: 40Go + 20Go + 10Go + 10Go)

Pour configurer le MIG, il faut modifier les labels suivants sur le noeud portant le GPU (voir script install-operator.sh, fonction `install_MIG`):

- 
- nvidia.com/mig.config

### Time Slicing

1. Mettre en place la configmap portant la configuration du Time Slicing, voir fichier `time-slicing-config-all.yaml`
2. Patcher la ressource `clusterpolicies.nvidia.com/cluster-policy` afin de lui signifier qu'une nouvelle configmap existe pour son configuration
3. Redémarrer le daemonset `nvidia-device-plugin-daemonset`

Ces étapes se retrouvent dans le script script install-operator.sh, fonction `install_time_slicing` et `update_time_slicing`

## Vérification

Pour vérifier que la configuration est bien prise en compte, afficher les labels du noeud portant le GPU:

- gpu.count: nombre de MIG configuré
- gpu.replicas: nombre de tranche pour le Time Slicing
- gpu.product: nom de la carte, contient le suffixe -SHARED en cas de découpage
- nvidia.com/gpu: nombre total de GPU disponible (= gpu.count * gpu.replicas)

Vérification des capacités des la carte graphique ainsi que de la chage de travail à un instant T:

```bash
k -n kube-system exec ds/nvidia-container-toolkit-daemonset -- chroot /run/nvidia/driver nvidia-smi
```

Vérification du nombre de MIG ainsi que la configuration associée:

```bash
k -n kube-system exec ds/nvidia-container-toolkit-daemonset -- chroot /run/nvidia/driver nvidia-smi mig -L
```

## Bonus

### Tests

Le fichier `testpod.yaml` permet de lancer un déploiement avec l'image vectoradd fournie par nvidia.

Le fait de placer le bloc suivant permet de limiter le nombre de GPU pour la tâche:

```yaml
resources:
  requests:
    nvidia.com/gpu: 1
  limits:
    nvidia.com/gpu: 1
```

**Pour les GPU il est imposé que requests == limits et limits doit être définie**

### Limitation des ressources par profil

Comme pour le CPU et la RAM, il est possible de limiter le nombre de GPU demandé par un namespace via un ResourceQuotas (fichier `compute-resources.yaml`):

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-resources
spec:
  hard:
    requests.nvidia.com/gpu: 4
```
