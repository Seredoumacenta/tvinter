#!/data/data/com.termux/files/usr/bin/bash

# Script Principal de Gestion des Chaînes TV
# Version Autonome avec Renouvellement Automatique

set -e

# === CONFIGURATION ===
CONFIG_DIR="$HOME/.tv_manager"
CHANNELS_FILE="$CONFIG_DIR/channels.conf"
ACCESS_FILE="$CONFIG_DIR/access.conf"
LOG_FILE="$CONFIG_DIR/access.log"
URLS_FILE="$CONFIG_DIR/urls.dat"
CODES_FILE="$CONFIG_DIR/codes.db"
CACHE_FILE="$CONFIG_DIR/cache_clean.log"
BROWSERS_FILE="$CONFIG_DIR/browsers.conf"

# Constantes de sécurité
SECRET_SEED="TV_MONTHLY_2024_SECURE_2024"

# Codes de recharge pour 1 mois
# ORANGE MONEY
RECHARGE_CODE_1="*144*1*1*622001839*30000#"
# MOBILE MONEY
RECHARGE_CODE_2="*440*1*1*663199359*30000#"

# Durée de validité en secondes (30 jours)
VALIDITY_SECONDS=2592000

# === COULEURS ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# === FONCTIONS D'AFFICHAGE ===
display_header() {
    clear
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════╗"
    echo "║   📺 GESTIONNAIRE TV AUTONOME       ║"
    echo "║  Renouvellement Automatique d'Accès ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
}

display_message() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

display_success() {
    display_message "$GREEN" "✅ $1"
}

display_error() {
    display_message "$RED" "❌ $1"
}

display_warning() {
    display_message "$YELLOW" "⚠️  $1"
}

display_info() {
    display_message "$CYAN" "ℹ️  $1"
}

# === AFFICHAGE CODES DE RECHARGE ===
display_recharge_codes() {
    echo -e "${YELLOW}📱 CODES DE RECHARGE POUR 1 MOIS${NC}"
    echo "┌────────────────────────────────────────┐"
    echo -e "│ ${GREEN}📞 ORANGE MONEY${NC}                         │"
    echo -e "│ ${CYAN}$RECHARGE_CODE_1${NC} │"
    echo "│────────────────────────────────────────│"
    echo -e "│ ${GREEN}📞 MOBILE MONEY${NC}                         │"
    echo -e "│ ${CYAN}$RECHARGE_CODE_2${NC} │"
    echo "└────────────────────────────────────────┘"
    echo ""
    echo -e "${PURPLE}ℹ️  Utilisez l'un de ces codes pour recharger${NC}"
    echo -e "${PURPLE}   votre abonnement d'un mois avant de continuer${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Après recharge, entrez le code secret ci-dessous${NC}"
    echo ""
}

# === GESTION DES NAVIGATEURS ===
detect_installed_browsers() {
    display_info "Détection des navigateurs installés..."
    
    local browsers=()
    
    # Recherche des navigateurs via pm (Package Manager)
    if command -v pm > /dev/null; then
        while IFS= read -r package; do
            if [[ -n "$package" ]]; then
                browsers+=("$package")
            fi
        done < <(pm list packages -f | grep -i -E '(browser|chrome|firefox|webview|opera|edge|brave|ucbrowser|dolphin)' | cut -d: -f2 | sort -u 2>/dev/null || true)
    fi
    
    # Ajout des navigateurs courants manuellement
    local common_browsers=(
        "com.android.chrome"
        "com.chrome.beta"
        "org.mozilla.firefox"
        "org.mozilla.fenix"
        "com.opera.browser"
        "com.opera.mini.native"
        "com.microsoft.emmx"
        "com.brave.browser"
        "com.uc.browser.en"
        "mobi.mgeek.TunnyBrowser"
        "app.lokke.main"
        "com.termux"
    )
    
    for browser in "${common_browsers[@]}"; do
        if command -v pm > /dev/null && pm list packages 2>/dev/null | grep -q "$browser"; then
            if [[ ! " ${browsers[@]} " =~ " $browser " ]]; then
                browsers+=("$browser")
            fi
        fi
    done
    
    if [[ ${#browsers[@]} -eq 0 ]]; then
        echo ""
    else
        printf '%s\n' "${browsers[@]}"
    fi
}

get_browser_name() {
    local package="$1"
    case "$package" in
        "com.android.chrome") echo "Google Chrome" ;;
        "com.chrome.beta") echo "Chrome Beta" ;;
        "org.mozilla.firefox") echo "Firefox" ;;
        "org.mozilla.fenix") echo "Firefox Nightly" ;;
        "com.opera.browser") echo "Opera" ;;
        "com.opera.mini.native") echo "Opera Mini" ;;
        "com.microsoft.emmx") echo "Microsoft Edge" ;;
        "com.brave.browser") echo "Brave Browser" ;;
        "com.uc.browser.en") echo "UC Browser" ;;
        "mobi.mgeek.TunnyBrowser") echo "Dolphin Browser" ;;
        "app.lokke.main") echo "Lokke TV Browser" ;;
        "com.termux") echo "Termux" ;;
        *) echo "$package" ;;
    esac
}

select_default_browser() {
    display_header
    echo -e "${YELLOW}🌐 Sélection du Navigateur par Défaut${NC}"
    echo ""
    
    local browsers=($(detect_installed_browsers))
    
    if [[ ${#browsers[@]} -eq 0 ]] || [[ -z "${browsers[0]}" ]]; then
        display_error "Aucun navigateur détecté"
        echo ""
        echo -e "${YELLOW}Veuillez installer un navigateur comme Chrome ou Firefox${NC}"
        read -p "Appuyez sur Entrée pour continuer..."
        return 1
    fi
    
    echo -e "${PURPLE}📋 Navigateurs détectés:${NC}"
    echo "┌────────────────────────────────────────┐"
    
    local counter=1
    for browser in "${browsers[@]}"; do
        if [[ -n "$browser" ]]; then
            local browser_name=$(get_browser_name "$browser")
            printf "│ ${CYAN}%2d. %-35s${NC} │\n" "$counter" "$browser_name"
            counter=$((counter + 1))
        fi
    done
    echo "└────────────────────────────────────────┘"
    echo ""
    
    echo -n -e "${YELLOW}Choisissez un navigateur (1-${#browsers[@]}): ${NC}"
    read choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#browsers[@]} ]]; then
        local selected_browser="${browsers[$((choice-1))]}"
        local selected_name=$(get_browser_name "$selected_browser")
        
        # Sauvegarder le choix
        echo "$selected_browser" > "$BROWSERS_FILE"
        display_success "Navigateur par défaut: $selected_name"
        
        # Tester l'ouverture avec le navigateur sélectionné
        test_browser_opening "$selected_browser" "$selected_name"
    else
        display_error "Choix invalide"
    fi
    
    read -p "Appuyez sur Entrée pour continuer..."
}

test_browser_opening() {
    local browser_package="$1"
    local browser_name="$2"
    
    display_info "Test d'ouverture avec $browser_name..."
    
    # Méthode 1: Utiliser termux-open-url avec le navigateur spécifique
    if command -v termux-open-url > /dev/null; then
        if termux-open-url "https://example.com" 2>/dev/null; then
            display_success "Test réussi avec termux-open-url"
            return 0
        fi
    fi
    
    # Méthode 2: Utiliser am start avec le package spécifique
    if am start -a android.intent.action.VIEW -d "https://example.com" -n "$browser_package/.App" 2>/dev/null; then
        display_success "Test réussi avec am start"
        return 0
    fi
    
    # Méthode 3: Ouvrir les paramètres par défaut
    display_warning "Ouvrez les paramètres et sélectionnez $browser_name comme navigateur par défaut"
    am start -a android.settings.MANAGE_DEFAULT_APPS_SETTINGS 2>/dev/null
    
    read -p "Appuyez sur Entrée une fois la configuration terminée..."
    display_success "Configuration de $browser_name terminée"
    return 0
}

get_default_browser() {
    if [[ -f "$BROWSERS_FILE" ]] && [[ -s "$BROWSERS_FILE" ]]; then
        cat "$BROWSERS_FILE"
    else
        echo "com.android.chrome"  # Valeur par défaut
    fi
}

open_url_with_browser() {
    local url="$1"
    local browser_package=$(get_default_browser)
    
    display_info "Ouverture avec $(get_browser_name "$browser_package")..."
    
    # Essayer termux-open-url d'abord
    if command -v termux-open-url > /dev/null; then
        if termux-open-url "$url" 2>/dev/null; then
            return 0
        fi
    fi
    
    # Fallback avec am start
    if am start -a android.intent.action.VIEW -d "$url" -n "$browser_package/.App" 2>/dev/null; then
        return 0
    fi
    
    # Dernier recours
    am start -a android.intent.action.VIEW -d "$url" 2>/dev/null
    return $?
}

# === FONCTIONS DE NETTOYAGE CACHE ===
clean_application_cache() {
    display_info "Nettoyage du cache des applications..."
    
    local cleaned=0
    
    if command -v pm > /dev/null; then
        display_info "Nettoyage cache avec pm..."
        if pm trim-caches 256M 2>/dev/null; then
            display_success "Cache système nettoyé"
            cleaned=$((cleaned + 1))
        fi
    fi
    
    display_info "Nettoyage des caches utilisateur..."
    if [[ -d "/data/data/com.termux/cache" ]]; then
        if rm -rf /data/data/com.termux/cache/* 2>/dev/null; then
            display_success "Cache Termux nettoyé"
            cleaned=$((cleaned + 1))
        fi
    fi
    
    display_info "Nettoyage des fichiers temporaires..."
    if find /data/data/com.termux -name "*.tmp" -delete 2>/dev/null; then
        display_success "Fichiers temporaires supprimés"
        cleaned=$((cleaned + 1))
    fi
    
    display_info "Nettoyage des logs volumineux..."
    if find "$CONFIG_DIR" -name "*.log" -size +1M -exec truncate -s 0 {} \; 2>/dev/null; then
        display_success "Logs volumineux tronqués"
        cleaned=$((cleaned + 1))
    fi
    
    if [[ $cleaned -gt 0 ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Cache nettoyé - $cleaned opérations" >> "$CACHE_FILE"
        display_success "Nettoyage terminé: $cleaned opérations effectuées"
    else
        display_warning "Aucun cache à nettoyer"
    fi
}

clear_application_data() {
    local app_package="$1"
    display_warning "Suppression des données de: $app_package"
    
    if command -v pm > /dev/null; then
        if pm clear "$app_package" 2>/dev/null; then
            display_success "Données de $app_package supprimées"
            echo "$(date '+%Y-%m-d %H:%M:%S') - Données supprimées: $app_package" >> "$CACHE_FILE"
        else
            display_error "Impossible de supprimer $app_package"
        fi
    else
        display_error "Commande pm non disponible"
    fi
}

automatic_cache_clean() {
    if [[ -f "$CACHE_FILE" ]] && [[ -s "$CACHE_FILE" ]]; then
        local last_clean_line=$(tail -1 "$CACHE_FILE")
        local last_clean=$(date -d "$(echo "$last_clean_line" | cut -d' ' -f1-2)" +%s 2>/dev/null || echo 0)
        local current_date=$(date +%s)
        local days_since_clean=$(( (current_date - last_clean) / 86400 ))
        
        if [[ $days_since_clean -ge 7 ]]; then
            display_info "Nettoyage automatique du cache..."
            clean_application_cache
        fi
    else
        clean_application_cache
    fi
}

# === FONCTIONS DE SÉCURITÉ ===
generate_access_code() {
    local month="$1"
    echo -n "${month}${SECRET_SEED}" | md5sum | cut -c1-8 | tr '[:lower:]' '[:upper:]'
}

get_stored_code() {
    local month="$1"
    if [[ -f "$CODES_FILE" ]]; then
        grep "^$month:" "$CODES_FILE" 2>/dev/null | cut -d: -f2
    else
        echo ""
    fi
}

verify_code_against_db() {
    local month="$1"
    local user_code="$2"
    local stored_code=$(get_stored_code "$month")
    
    [[ "$user_code" == "$stored_code" ]]
}

# === GESTION DES CODES ===
initialize_codes() {
    for i in {0..5}; do
        local future_month=$(date -d "+$i months" +%Y%m 2>/dev/null || echo "")
        if [[ -n "$future_month" ]] && ! grep -q "^$future_month:" "$CODES_FILE" 2>/dev/null; then
            local code=$(generate_access_code "$future_month")
            echo "$future_month:$code" >> "$CODES_FILE"
        fi
    done
}

validate_current_month() {
    local current_month=$(date +%Y%m)
    local current_timestamp=$(date +%s)
    local expire_timestamp=$((current_timestamp + VALIDITY_SECONDS)) # 30 jours
    
    # Créer une entrée chronologique
    local temp_file=$(mktemp 2>/dev/null || echo "/tmp/tv_manager_temp_$$")
    if [[ -f "$ACCESS_FILE" ]]; then
        grep -v "^$current_month:" "$ACCESS_FILE" > "$temp_file" 2>/dev/null || true
    else
        > "$temp_file"
    fi
    echo "$current_month:$current_timestamp:$expire_timestamp" >> "$temp_file"
    mv "$temp_file" "$ACCESS_FILE" 2>/dev/null
    
    local expire_date=$(date -d "@$expire_timestamp" '+%d/%m/%Y %H:%M' 2>/dev/null || echo "date inconnue")
    display_success "Mois $(date +"%B %Y") validé jusqu'au $expire_date"
}

is_current_month_valid() {
    local current_month=$(date +%Y%m)
    
    if [[ ! -f "$ACCESS_FILE" ]]; then
        return 1
    fi
    
    local entry=$(grep "^$current_month:" "$ACCESS_FILE" 2>/dev/null)
    
    if [[ -n "$entry" ]]; then
        local expire_timestamp=$(echo "$entry" | cut -d: -f3)
        local current_timestamp=$(date +%s)
        
        if [[ -n "$expire_timestamp" ]] && [[ $current_timestamp -lt $expire_timestamp ]]; then
            return 0  # Valide
        fi
    fi
    return 1  # Non valide ou expiré
}

is_code_expired() {
    local current_month=$(date +%Y%m)
    
    if [[ ! -f "$ACCESS_FILE" ]]; then
        return 0
    fi
    
    local entry=$(grep "^$current_month:" "$ACCESS_FILE" 2>/dev/null)
    
    if [[ -z "$entry" ]]; then
        return 0  # Pas d'entrée, donc considéré comme expiré
    fi
    
    local expire_timestamp=$(echo "$entry" | cut -d: -f3)
    local current_timestamp=$(date +%s)
    
    if [[ -z "$expire_timestamp" ]] || [[ $current_timestamp -ge $expire_timestamp ]]; then
        return 0  # Expiré
    else
        return 1  # Non expiré
    fi
}

get_days_remaining() {
    local current_month=$(date +%Y%m)
    
    if [[ ! -f "$ACCESS_FILE" ]]; then
        echo "0"
        return
    fi
    
    local entry=$(grep "^$current_month:" "$ACCESS_FILE" 2>/dev/null)
    
    if [[ -n "$entry" ]]; then
        local expire_timestamp=$(echo "$entry" | cut -d: -f3)
        local current_timestamp=$(date +%s)
        
        if [[ -n "$expire_timestamp" ]]; then
            local seconds_remaining=$((expire_timestamp - current_timestamp))
            
            if [[ $seconds_remaining -gt 0 ]]; then
                echo $((seconds_remaining / 86400))
                return
            fi
        fi
    fi
    echo "0"
}

get_expiration_info() {
    local current_month=$(date +%Y%m)
    
    if [[ ! -f "$ACCESS_FILE" ]]; then
        echo "NO_ACCESS"
        return
    fi
    
    local entry=$(grep "^$current_month:" "$ACCESS_FILE" 2>/dev/null)
    
    if [[ -n "$entry" ]]; then
        local expire_timestamp=$(echo "$entry" | cut -d: -f3)
        local current_timestamp=$(date +%s)
        
        if [[ -n "$expire_timestamp" ]]; then
            if [[ $current_timestamp -ge $expire_timestamp ]]; then
                local expire_date=$(date -d "@$expire_timestamp" '+%d/%m/%Y %H:%M' 2>/dev/null || echo "date inconnue")
                echo "EXPIRED:$expire_date"
            else
                local days_remaining=$(( (expire_timestamp - current_timestamp) / 86400 ))
                local expire_date=$(date -d "@$expire_timestamp" '+%d/%m/%Y %H:%M' 2>/dev/null || echo "date inconnue")
                echo "VALID:$days_remaining:$expire_date"
            fi
            return
        fi
    fi
    echo "NO_ACCESS"
}

# === SYSTÈME AUTONOME D'ACCÈS ===
auto_renew_access() {
    local current_month=$(date +%Y%m)
    
    display_header
    echo -e "${YELLOW}🔄 RENOUVELLEMENT AUTOMATIQUE DU CODE${NC}"
    echo -e "${CYAN}Mois: $(date +"%B %Y")${NC}"
    echo -e "${PURPLE}Validité: 1 mois à partir d'aujourd'hui${NC}"
    echo ""
    
    # Afficher les codes de recharge
    display_recharge_codes
    
    local attempts=3
    while [[ $attempts -gt 0 ]]; do
        echo -n -e "${YELLOW}Entrez le NOUVEAU code secret: ${NC}"
        read -s user_code
        echo
        
        if verify_code_against_db "$current_month" "$user_code"; then
            validate_current_month
            display_success "Accès renouvelé pour 1 mois!"
            log_event "AUTO_RENEW_SUCCESS" "Accès renouvelé pour $(date +"%B %Y")"
            echo ""
            sleep 2
            return 0
        else
            attempts=$((attempts - 1))
            if [[ $attempts -gt 0 ]]; then
                display_error "Code incorrect. Tentatives restantes: $attempts"
            else
                display_error "Code incorrect."
            fi
            log_event "AUTO_RENEW_FAILED" "Tentative échouée pour $(date +"%B %Y")"
        fi
    done
    
    display_error "Renouvellement bloqué après 3 tentatives"
    echo ""
    display_warning "Le système va réessayer dans 30 secondes..."
    sleep 30
    return 1
}

check_and_renew_access() {
    while true; do
        if is_current_month_valid; then
            local days_remaining=$(get_days_remaining)
            if [[ $days_remaining -gt 0 ]]; then
                display_success "Accès valide - Expire dans $days_remaining jour(s)"
                return 0
            else
                display_warning "Code expiré - Renouvellement automatique..."
                # Le code continue directement vers la demande de nouveau code
            fi
        fi
        
        # Si on arrive ici, l'accès n'est pas valide
        if is_code_expired; then
            display_error "CODE D'ACCÈS EXPIRÉ - RENOUVELLEMENT REQUIS"
            echo ""
        else
            display_warning "Accès requis pour $(date +"%B %Y")"
        fi
        
        # Appel automatique de la fonction de renouvellement
        auto_renew_access
    done
}

check_upcoming_expiration() {
    local days_remaining=$(get_days_remaining)
    
    if [[ $days_remaining -eq 3 ]]; then
        display_warning "⚠️  Votre code expire dans 3 jours"
        echo "Pensez à préparer le renouvellement."
    elif [[ $days_remaining -eq 1 ]]; then
        display_warning "⚠️  Votre code expire DEMAIN"
        echo "Renouvellement recommandé dès aujourd'hui."
    fi
}

# === JOURNALISATION ===
log_event() {
    local status="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $status - $message" >> "$LOG_FILE"
}

# === GESTION DES CHAÎNES ===
get_channel_url() {
    local channel_name="$1"
    if [[ -f "$URLS_FILE" ]]; then
        grep "^${channel_name}|" "$URLS_FILE" 2>/dev/null | cut -d'|' -f2
    else
        echo ""
    fi
}

initialize_channels() {
    if [[ ! -f "$CHANNELS_FILE" ]]; then
        cat > "$CHANNELS_FILE" << EOF
# Format: nom|catégorie
Worldstv|streaming
TousTV |live
TV PAYS DU MONDE|international
EOF
    fi
    
    if [[ ! -f "$URLS_FILE" ]]; then
        cat > "$URLS_FILE" << EOF
# Format: nom|url
Worldstv|https://worldstvmobile.com/category/
TousTV |https://vavoo.to/
TV PAYS DU MONDE|https://famelack.com/
EOF
    fi
}

# === AFFICHAGE DES CHAÎNES ===
display_channels_list() {
    echo -e "${PURPLE}📋 Chaînes disponibles:${NC}"
    echo "┌────────────────────────────────────────┐"
    
    local counter=1
    if [[ -f "$CHANNELS_FILE" ]]; then
        while IFS='|' read -r name category; do
            if [[ ! "$name" =~ ^# ]] && [[ -n "$name" ]]; then
                printf "│ ${CYAN}%2d. %-25s${NC} │\n" "$counter" "$name"
                printf "│    ${GREEN}🏷️  %-28s${NC} │\n" "$category"
                echo "│────────────────────────────────────────│"
                counter=$((counter + 1))
            fi
        done < "$CHANNELS_FILE"
    fi
    
    if [[ $counter -eq 1 ]]; then
        echo -e "│ ${YELLOW}   Aucune chaîne configurée${NC}         │"
    fi
    echo "└────────────────────────────────────────┘"
}

# === OPÉRATIONS SUR LES CHAÎNES ===
open_channel() {
    # Vérifier strictement l'accès avant d'ouvrir une chaîne
    if ! is_current_month_valid; then
        display_error "Accès non valide ou expiré"
        echo ""
        display_warning "Renouvellement automatique en cours..."
        if check_and_renew_access; then
            display_success "Accès renouvelé! Vous pouvez maintenant ouvrir une chaîne."
            echo ""
        else
            display_error "Impossible d'ouvrir une chaîne sans accès valide"
            read -p "Appuyez sur Entrée pour continuer..."
            return 1
        fi
    fi
    
    display_channels_list
    echo ""
    echo -n -e "${YELLOW}Choisissez le numéro de la chaîne: ${NC}"
    read choice
    
    if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
        display_error "Choix invalide!"
        read -p "Appuyez sur Entrée pour continuer..."
        return 1
    fi
    
    local channel_data=$(sed -n "${choice}p" "$CHANNELS_FILE" 2>/dev/null)
    
    if [[ -n "$channel_data" ]]; then
        local channel_name=$(echo "$channel_data" | cut -d'|' -f1)
        local channel_url=$(get_channel_url "$channel_name")
        
        if [[ -n "$channel_url" ]]; then
            display_info "Ouverture de: $channel_name"
            
            if open_url_with_browser "$channel_url"; then
                display_success "Chaîne ouverte avec succès!"
                log_event "CHANNEL_OPEN" "Ouverture: $channel_name"
            else
                display_error "Erreur lors de l'ouverture"
            fi
        else
            display_error "URL non trouvée pour cette chaîne"
        fi
    else
        display_error "Choix invalide!"
    fi
    
    read -p "Appuyez sur Entrée pour continuer..."
}

add_channel() {
    # Vérifier l'accès pour les opérations d'administration
    if ! is_current_month_valid; then
        display_error "Accès non valide pour cette opération"
        echo ""
        display_warning "Renouvellement automatique en cours..."
        if check_and_renew_access; then
            display_success "Accès renouvelé! Vous pouvez maintenant ajouter une chaîne."
            echo ""
        else
            read -p "Appuyez sur Entrée pour continuer..."
            return 1
        fi
    fi
    
    display_header
    echo -e "${YELLOW}➕ Ajout d'une nouvelle chaîne${NC}"
    echo ""
    
    echo -n "Nom de la chaîne: "
    read channel_name
    echo -n "URL: "
    read channel_url
    echo -n "Catégorie: "
    read channel_category
    
    if [[ -n "$channel_name" && -n "$channel_url" && -n "$channel_category" ]]; then
        echo "$channel_name|$channel_category" >> "$CHANNELS_FILE"
        echo "$channel_name|$channel_url" >> "$URLS_FILE"
        display_success "Chaîne ajoutée avec succès!"
        log_event "CHANNEL_ADD" "Nouvelle chaîne: $channel_name"
    else
        display_error "Tous les champs sont requis!"
    fi
    
    read -p "Appuyez sur Entrée pour continuer..."
}

delete_channel() {
    # Vérifier l'accès pour les opérations d'administration
    if ! is_current_month_valid; then
        display_error "Accès non valide pour cette opération"
        echo ""
        display_warning "Renouvellement automatique en cours..."
        if check_and_renew_access; then
            display_success "Accès renouvelé! Vous pouvez maintenant supprimer une chaîne."
            echo ""
        else
            read -p "Appuyez sur Entrée pour continuer..."
            return 1
        fi
    fi
    
    display_channels_list
    echo ""
    echo -n -e "${RED}Choisissez le numéro à supprimer: ${NC}"
    read choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        local channel_data=$(sed -n "${choice}p" "$CHANNELS_FILE" 2>/dev/null)
        local channel_name=$(echo "$channel_data" | cut -d'|' -f1)
        
        if [[ -n "$channel_name" ]]; then
            echo -n -e "${RED}Supprimer '$channel_name'? (o/n): ${NC}"
            read confirm
            
            if [[ "$confirm" == "o" || "$confirm" == "O" ]]; then
                sed -i "${choice}d" "$CHANNELS_FILE" 2>/dev/null
                sed -i "/^${channel_name}|/d" "$URLS_FILE" 2>/dev/null
                
                display_success "Chaîne supprimée!"
                log_event "CHANNEL_DELETE" "Chaîne supprimée: $channel_name"
            else
                display_warning "Suppression annulée"
            fi
        else
            display_error "Chaîne non trouvée"
        fi
    else
        display_error "Choix invalide!"
    fi
    
    read -p "Appuyez sur Entrée pour continuer..."
}

# === STATISTIQUES ===
display_statistics() {
    echo -e "${PURPLE}📊 Statistiques d'accès${NC}"
    echo "┌────────────────────────────────────────┐"
    
    if [[ -f "$LOG_FILE" ]]; then
        local total_access=$(grep -c "CHANNEL_OPEN" "$LOG_FILE" 2>/dev/null || echo "0")
        local failed_attempts=$(grep -c "FAILED\|AUTO_RENEW_FAILED" "$LOG_FILE" 2>/dev/null || echo "0")
        local auto_renewals=$(grep -c "AUTO_RENEW_SUCCESS" "$LOG_FILE" 2>/dev/null || echo "0")
        local total_channels=0
        local current_browser=$(get_browser_name "$(get_default_browser)")
        local last_access="Aucun"
        
        if [[ -f "$CHANNELS_FILE" ]]; then
            total_channels=$(grep -c "|" "$CHANNELS_FILE" 2>/dev/null || echo "0")
        fi
        
        if [[ -f "$LOG_FILE" ]]; then
            last_access_line=$(grep -E "(SUCCESS|AUTO_RENEW_SUCCESS)" "$LOG_FILE" 2>/dev/null | tail -1)
            if [[ -n "$last_access_line" ]]; then
                last_access=$(echo "$last_access_line" | cut -d'-' -f3-)
            fi
        fi
        
        printf "│ ${CYAN}%-20s: %-15s${NC} │\n" "Chaînes totales" "$total_channels"
        printf "│ ${GREEN}%-20s: %-15s${NC} │\n" "Accès aux chaînes" "$total_access"
        printf "│ ${BLUE}%-20s: %-15s${NC} │\n" "Renouvellements auto" "$auto_renewals"
        printf "│ ${RED}%-20s: %-15s${NC} │\n" "Tentatives échouées" "$failed_attempts"
        printf "│ ${YELLOW}%-20s: %-15s${NC} │\n" "Navigateur" "$current_browser"
        printf "│ ${PURPLE}%-20s: %-15s${NC} │\n" "Dernier accès" "$last_access"
        
        # Afficher le statut d'accès
        local exp_info=$(get_expiration_info)
        case "$exp_info" in
            "NO_ACCESS")
                printf "│ ${RED}%-20s: %-15s${NC} │\n" "Statut accès" "NON VALIDÉ"
                ;;
            "EXPIRED:"*)
                local expire_date="${exp_info#EXPIRED:}"
                printf "│ ${RED}%-20s: %-15s${NC} │\n" "Statut accès" "EXPIRÉ"
                printf "│ ${RED}%-20s: %-15s${NC} │\n" "Depuis le" "$expire_date"
                ;;
            "VALID:"*)
                local days_remaining=$(echo "$exp_info" | cut -d: -f2)
                local expire_date=$(echo "$exp_info" | cut -d: -f3)
                printf "│ ${GREEN}%-20s: %-15s${NC} │\n" "Statut accès" "VALIDE"
                printf "│ ${GREEN}%-20s: %-15s${NC} │\n" "Jours restants" "$days_remaining"
                printf "│ ${GREEN}%-20s: %-15s${NC} │\n" "Expire le" "$expire_date"
                ;;
        esac
    else
        echo -e "│ ${YELLOW}   Aucune statistique disponible${NC}    │"
    fi
    echo "└────────────────────────────────────────┘"
}

# === MENUS ===
display_main_menu() {
    display_header
    
    # Afficher l'avertissement d'expiration proche
    check_upcoming_expiration
    
    # Affichage du statut d'accès et navigateur
    local exp_info=$(get_expiration_info)
    case "$exp_info" in
        "NO_ACCESS")
            echo -e "${RED}📅 ACCÈS NON VALIDÉ${NC}"
            echo -e "${YELLOW}Renouvellement automatique activé${NC}"
            ;;
        "EXPIRED:"*)
            local expire_date="${exp_info#EXPIRED:}"
            echo -e "${RED}📅 CODE EXPIRÉ${NC}"
            echo -e "${YELLOW}Redirection automatique vers renouvellement${NC}"
            ;;
        "VALID:"*)
            local days_remaining=$(echo "$exp_info" | cut -d: -f2)
            local expire_date=$(echo "$exp_info" | cut -d: -f3)
            if [[ $days_remaining -gt 0 ]]; then
                echo -e "${GREEN}📅 Accès valide - $days_remaining jour(s) restant(s)${NC}"
            else
                echo -e "${RED}📅 Code expiré - Renouvellement automatique${NC}"
            fi
            ;;
    esac
    
    local current_browser=$(get_browser_name "$(get_default_browser)")
    echo -e "${BLUE}🌐 Navigateur: $current_browser${NC}"
    echo ""
    
    echo -e "${PURPLE}Options:${NC}"
    echo "┌────────────────────────────────────────┐"
    echo "│   1. 📡 Ouvrir une chaîne              │"
    echo "│   2. 📋 Lister les chaînes             │"
    echo "│   3. ➕ Ajouter une chaîne             │"
    echo "│   4. 🗑️  Supprimer une chaîne          │"
    echo "│   5. 🌐 Changer navigateur             │"
    echo "│   6. 🔄 Code du mois prochain          │"
    echo "│   7. 📊 Statistiques                   │"
    echo "│   8. 🧹 Nettoyer le cache              │"
    echo "│   9. 🗂️  Gestion avancée               │"
    echo "│   0. 🚪 Quitter                        │"
    echo "└────────────────────────────────────────┘"
    echo ""
}

display_advanced_menu() {
    display_header
    echo -e "${PURPLE}🛠️  Gestion Avancée${NC}"
    echo "┌────────────────────────────────────────┐"
    echo "│   1. 🧹 Nettoyer cache spécifique      │"
    echo "│   2. 🗑️  Supprimer données app         │"
    echo "│   3. 📋 Logs de nettoyage              │"
    echo "│   4. 🔍 Statut système                 │"
    echo "│   5. 🔍 Détecter navigateurs           │"
    echo "│   6. ↩️  Retour menu principal         │"
    echo "└────────────────────────────────────────┘"
    echo ""
    
    echo -n -e "${YELLOW}Choisissez une option (1-6): ${NC}"
    read advanced_choice
    
    case $advanced_choice in
        1) 
            clean_application_cache
            read -p "Appuyez sur Entrée pour continuer..."
            ;;
        2)
            echo -n "Nom du package (ex: com.android.chrome): "
            read app_package
            clear_application_data "$app_package"
            read -p "Appuyez sur Entrée pour continuer..."
            ;;
        3)
            display_cache_logs
            ;;
        4)
            display_system_status
            ;;
        5)
            detect_and_display_browsers
            ;;
        6)
            return
            ;;
        *)
            display_error "Option invalide!"
            read -p "Appuyez sur Entrée pour continuer..."
            ;;
    esac
}

display_next_month_code() {
    # Vérifier l'accès actuel avant d'afficher le code du mois prochain
    if ! is_current_month_valid; then
        display_error "Accès actuel non valide"
        display_warning "Renouvellement automatique en cours..."
        if check_and_renew_access; then
            display_success "Accès renouvelé! Affichage du code du mois prochain..."
            echo ""
        else
            read -p "Appuyez sur Entrée pour continuer..."
            return 1
        fi
    fi
    
    local next_month=$(date -d "next month" +%Y%m 2>/dev/null || echo "")
    local next_month_name=$(date -d "next month" +"%B %Y" 2>/dev/null || echo "Mois prochain")
    local next_month_code=$(get_stored_code "$next_month")
    
    if [[ -z "$next_month_code" ]]; then
        next_month_code=$(generate_access_code "$next_month")
        echo "$next_month:$next_month_code" >> "$CODES_FILE"
    fi
    
    echo -e "${YELLOW}🔮 Code du mois prochain${NC}"
    echo "┌────────────────────────────────────────┐"
    echo -e "│ ${CYAN}Mois: $next_month_name${NC}                   │"
    echo -e "│ ${GREEN}✅ Code généré et sécurisé${NC}              │"
    echo -e "│ ${BLUE}ℹ️  Demandé le 1er $next_month_name${NC}     │"
    echo "└────────────────────────────────────────┘"
    echo ""
    
    # Afficher aussi les codes de recharge
    echo -e "${YELLOW}📱 Codes de recharge pour le mois prochain:${NC}"
    echo "┌────────────────────────────────────────┐"
    echo -e "│ ${GREEN}ORANGE MONEY${NC}                           │"
    echo -e "│ ${CYAN}$RECHARGE_CODE_1${NC} │"
    echo "│────────────────────────────────────────│"
    echo -e "│ ${GREEN}MOBILE MONEY${NC}                           │"
    echo -e "│ ${CYAN}$RECHARGE_CODE_2${NC} │"
    echo "└────────────────────────────────────────┘"
    
    log_event "CODE_PREVIEW" "Consultation code $next_month_name"
    read -p "Appuyez sur Entrée pour continuer..."
}

display_cache_logs() {
    if [[ -f "$CACHE_FILE" ]] && [[ -s "$CACHE_FILE" ]]; then
        echo -e "${PURPLE}📋 Logs de Nettoyage${NC}"
        echo "┌────────────────────────────────────────┐"
        tail -10 "$CACHE_FILE" | while read -r line; do
            echo -e "│ ${CYAN}$line${NC} │"
        done
        echo "└────────────────────────────────────────┘"
    else
        display_warning "Aucun log de nettoyage disponible"
    fi
    read -p "Appuyez sur Entrée pour continuer..."
}

display_system_status() {
    echo -e "${PURPLE}🔍 Statut Système${NC}"
    echo "┌────────────────────────────────────────┐"
    
    # Mémoire libre
    local free_mem="N/A"
    if command -v free > /dev/null; then
        free_mem=$(free -m | awk 'NR==2{print $4 " MB"}' 2>/dev/null || echo "N/A")
    fi
    
    # Stockage
    local free_storage="N/A"
    if command -v df > /dev/null; then
        free_storage=$(df -h /data 2>/dev/null | awk 'NR==2{print $4}' || echo "N/A")
    fi
    
    # Uptime
    local uptime_info="N/A"
    if command -v uptime > /dev/null; then
        uptime_info=$(uptime -p 2>/dev/null | sed 's/up //' || echo "N/A")
    fi
    
    echo -e "│ ${CYAN}Mémoire libre: $free_mem${NC}       │"
    echo -e "│ ${GREEN}Stockage: $free_storage libre${NC}        │"
    echo -e "│ ${BLUE}Uptime: $uptime_info${NC}          │"
    echo -e "│ ${YELLOW}Date système: $(date '+%d/%m/%Y %H:%M')${NC} │"
    echo "└────────────────────────────────────────┘"
    read -p "Appuyez sur Entrée pour continuer..."
}

detect_and_display_browsers() {
    local browsers=($(detect_installed_browsers))
    
    echo -e "${PURPLE}🔍 Navigateurs Détectés${NC}"
    echo "┌────────────────────────────────────────┐"
    
    if [[ ${#browsers[@]} -eq 0 ]] || [[ -z "${browsers[0]}" ]]; then
        echo -e "│ ${YELLOW}   Aucun navigateur détecté${NC}         │"
    else
        for browser in "${browsers[@]}"; do
            if [[ -n "$browser" ]]; then
                local browser_name=$(get_browser_name "$browser")
                echo -e "│ ${CYAN}📍 $browser_name${NC}                   │"
            fi
        done
    fi
    echo "└────────────────────────────────────────┘"
    read -p "Appuyez sur Entrée pour continuer..."
}

handle_menu_choice() {
    local choice="$1"
    
    case $choice in
        1) 
            open_channel
            ;;
        2) 
            display_header
            display_channels_list
            read -p "Appuyez sur Entrée pour continuer..."
            ;;
        3) 
            add_channel
            ;;
        4) 
            delete_channel
            ;;
        5) 
            select_default_browser
            ;;
        6) 
            display_header
            display_next_month_code
            ;;
        7) 
            display_header
            display_statistics
            read -p "Appuyez sur Entrée pour continuer..."
            ;;
        8) 
            clean_application_cache
            read -p "Appuyez sur Entrée pour continuer..."
            ;;
        9)
            display_advanced_menu
            ;;
        0) 
            display_success "Au revoir!"
            log_event "EXIT" "Déconnexion normale"
            exit 0 
            ;;
        *) 
            display_error "Option invalide!"
            read -p "Appuyez sur Entrée pour continuer..."
            ;;
    esac
}

# === INITIALISATION ===
initialize_config() {
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
    fi
    
    initialize_channels
    
    if [[ ! -f "$CODES_FILE" ]]; then
        initialize_codes
    fi
    
    automatic_cache_clean
}

# === FONCTION PRINCIPALE ===
main() {
    initialize_config
    
    # Système autonome de vérification et renouvellement
    if ! check_and_renew_access; then
        # En cas d'échec persistant, le système boucle automatiquement
        # via la fonction check_and_renew_access()
        echo "Système en attente de renouvellement..."
    fi
    
    # Si le code est valide, continuer vers le menu principal
    while true; do
        # Vérifier discrètement si l'accès est toujours valide
        if ! is_current_month_valid; then
            display_warning "Votre session a expiré"
            echo "Redirection vers le renouvellement..."
            sleep 2
            check_and_renew_access
        fi
        
        display_main_menu
        echo -n -e "${YELLOW}Choisissez une option (0-9): ${NC}"
        read choice
        handle_menu_choice "$choice"
    done
}

# === GESTION DES ARGUMENTS ===
case "${1:-}" in
    "list")
        display_channels_list
        ;;
    "stats")
        display_statistics
        ;;
    "status")
        local exp_info=$(get_expiration_info)
        case "$exp_info" in
            "NO_ACCESS")
                display_error "ACCÈS NON VALIDÉ"
                echo "Renouvellement automatique activé"
                ;;
            "EXPIRED:"*)
                local expire_date="${exp_info#EXPIRED:}"
                display_error "CODE EXPIRÉ"
                echo "Expiré depuis: $expire_date"
                echo "Redirection automatique vers renouvellement"
                ;;
            "VALID:"*)
                local days_remaining=$(echo "$exp_info" | cut -d: -f2)
                local expire_date=$(echo "$exp_info" | cut -d: -f3)
                if [[ $days_remaining -gt 0 ]]; then
                    display_success "Accès valide - $days_remaining jour(s) restant(s)"
                    echo "Expire le: $expire_date"
                else
                    display_error "Code expiré - Renouvellement automatique"
                fi
                ;;
        esac
        ;;
    "clean")
        clean_application_cache
        ;;
    "browser")
        select_default_browser
        ;;
    "renew"|"auto")
        check_and_renew_access
        ;;
    "recharge")
        display_header
        display_recharge_codes
        read -p "Appuyez sur Entrée pour continuer..."
        ;;
    *)
        main
        ;;
esac
