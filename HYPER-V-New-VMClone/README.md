# New-VMClone

En s'appuyant sur les fonctionnalités d'export et d'importer d'Hyper-V, nous allons cloner une machine virtuelle existante.
Cette version n'intègre pas de paramètres, il faut modifier les valeurs suivantes directement dans le script : $VMSourceName (VM source à cloner), $VMCloneName (nom du clone),
$VMCloneExportPath (dossier dans lequel stocker l'export), $VMCloneImportConfigPath (dossier dans lequel créer les fichiers de configuration de la VM importée), $VMCloneImportVhdxPath (dossier dans lequel stocker les disques
virtuels de la VM importée)

# Examples

Le script est préconfiguré pour cloner la VM "Windows-10" en "Windows-10-Clone".
L'export sera stocké à l'emplacement suivant et il sera supprimé à la fin de l'opération (cela n'altère pas la VM source) : "C:\TEMP"
L'import, c'est-à-dire le clone, aura des fichiers de configuration stockés à cet emplacement : C:\ProgramData\Microsoft\Windows\Hyper-V\Virtual Machines\Windows-10-Clone
Les disques virtuels du clone seront quant à eux à cet emplacement : C:\ProgramData\Microsoft\Windows\Hyper-V\Virtual Machines\Windows-10-Clone\VHDX

# Links

[Cloner une VM avec Hyper-V](https://www.it-connect.fr/hyper-v-comment-cloner-une-vm/)