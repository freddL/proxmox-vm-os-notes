#!/bin/bash
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Lister toutes les VMs KVM (pas les containers LXC)
for vmid in $(qm list | awk 'NR>1 {print $1}'); do
    echo "🔍 VMID: $vmid"

    # Vérifier si l'agent invité est activé
    agent_enabled=$(qm config $vmid | grep agent: | awk '{print $2}')
    if [[ "$agent_enabled" != "1" ]]; then
        echo "   ⚠️ Agent invité désactivé, on passe."
        continue
    fi

    # Récupérer infos OS via QEMU Guest Agent
    osinfo=$(qm guest cmd $vmid get-osinfo 2>/dev/null)

    if [[ -z "$osinfo" ]]; then
        echo "   ❌ Impossible de récupérer l'OS."
        continue
    fi

    # Extraire nom "pretty-name"
    os_name=$(echo "$osinfo" | jq -r '.["pretty-name"] // .name')

    echo "   ✅ OS détecté: $os_name"
    echo "   ➡️ Mise à jour des notes de la VM..."

    # Mettre à jour les notes (remplace le contenu existant)
    pvesh set /nodes/$(hostname)/qemu/$vmid/config -description "OS détecté: $os_name"
done
