#!/bin/bash

# Script pour configurer l'exécution automatique de ~/chainetv/all.sh
# dans le fichier .bashrc

echo "=== Configuration de l'exécution automatique de ~/chainetv/All.sh ==="

# 1. Créer une sauvegarde de .bashrc
echo "1. Création d'une sauvegarde de ~/.bashrc..."
if cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S); then
    echo "   ✓ Sauvegarde créée avec succès"
else
    echo "   ✗ Erreur lors de la création de la sauvegarde"
    exit 1
fi

# 2. Vérifier si la commande existe déjà
echo "2. Vérification si la commande est déjà présente..."
if grep -q "bash ~/chainetv/all.sh" ~/.bashrc; then
    echo "   ✓ La commande est déjà présente dans ~/.bashrc"
    echo "   Aucune modification nécessaire."
else
    # 3. Ajouter la commande à .bashrc
    echo "3. Ajout de la commande à ~/.bashrc..."
    
    # Ajouter un commentaire et la commande
    echo "" >> ~/.bashrc
    echo "# Exécution automatique de chainetv/all.sh" >> ~/.bashrc
    echo "bash ~/chainetv/all.sh" >> ~/.bashrc
    
    if grep -q "bash ~/chainetv/all.sh" ~/.bashrc; then
        echo "   ✓ Commande ajoutée avec succès"
    else
        echo "   ✗ Erreur lors de l'ajout de la commande"
        exit 1
    fi
fi

# 4. Vérifier si le script all.sh existe et est exécutable
echo "4. Vérification du script ~/chainetv/all.sh..."
if [ -f ~/chainetv/All.sh ]; then
    echo "   ✓ Le script all.sh existe"
    
    # Vérifier s'il est exécutable
    if [ -x ~/chainetv/All.sh ]; then
        echo "   ✓ Le script est déjà exécutable"
    else
        echo "   - Le script n'est pas exécutable, configuration des permissions..."
        if chmod +x ~/chainetv/All.sh; then
            echo "   ✓ Permissions d'exécution accordées"
        else
            echo "   ✗ Erreur lors de la configuration des permissions"
        fi
    fi
else
    echo "   ⚠ Attention: ~/chainetv/all.sh n'existe pas encore"
    echo "   Vous devrez créer ce script pour que la configuration fonctionne"
fi

# 5. Options pour tester immédiatement
echo ""
echo "=== Configuration terminée avec succès! ==="
echo ""
echo "Options disponibles:"
echo "1. Tester immédiatement (recharger .bashrc)"
echo "2. Voir les 5 dernières lignes de .bashrc pour vérification"
echo "3. Quitter"
echo ""
read -p "Choisissez une option (1-3): " choice

case $choice in
    1)
        echo "Rechargement de .bashrc..."
        source ~/.bashrc
        echo "✓ .bashrc rechargé"
        echo "Le script s'exécutera automatiquement dans les nouveaux terminaux"
        ;;
    2)
        echo "=== Dernières lignes de ~/.bashrc ==="
        tail -5 ~/.bashrc
        echo "================================"
        ;;
    3)
        echo "Au revoir!"
        ;;
    *)
        echo "Option non reconnue"
        ;;
esac

echo ""
echo "N'oubliez pas:"
echo "- Le script s'exécutera dans chaque nouveau terminal"
echo "- Pour désactiver: supprimez la ligne 'bash ~/chainetv/All.sh' de ~/.bashrc"
echo "- Pour restaurer la sauvegarde: cp ~/.bashrc.backup.* ~/.bashrc"
