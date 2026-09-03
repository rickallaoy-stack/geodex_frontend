# main.py — Version sans Arduino (boutons terminal)
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

import time
import random
import requests
from config import API_URL, CAPTEUR_ID, SIGNATURE_EQUIPEMENT
from data_generator import generer_pesee_aleatoire
from sound_manager import jouer_son_conforme, jouer_son_fraude

def envoyer_pesee(mode_fraude=False):
    payload = generer_pesee_aleatoire(mode_fraude)
    statut = "🔴 FRAUDE" if mode_fraude else "🟢 CONFORME"
    print(f"\n[Simulateur] Envoi pesée {statut}...")
    print(f"  Poids    : {payload['poids_mesure_kg']} kg")
    print(f"  Position : {payload['latitude']:.4f}, {payload['longitude']:.4f}")

    try:
        response = requests.post(API_URL, json=payload, timeout=5)
        data = response.json()
        if mode_fraude:
            print(f"  ⚠️  Alerte détectée → {data.get('message', '')}")
            jouer_son_fraude()
        else:
            print(f"  ✅ Relevé enregistré → hash: {data.get('data', {}).get('hash_actuel', '')[:16]}...")
            jouer_son_conforme()
    except requests.exceptions.RequestException as e:
        print(f"  ❌ Erreur réseau : {e}")
        jouer_son_fraude()

def demarrer_simulation():
    print("=" * 50)
    print("   GEODEX — Simulateur IoT (mode PC)")
    print("=" * 50)
    print("\nCommandes :")
    print("  [Entrée]  → Lancer une vague (3-6 camions)")
    print("  [f]       → Forcer une pesée frauduleuse")
    print("  [c]       → Forcer une pesée conforme")
    print("  [q]       → Quitter")
    print("-" * 50)

    while True:
        choix = input("\n> ").strip().lower()

        if choix == "q":
            print("Arrêt du simulateur.")
            break

        elif choix == "f":
            envoyer_pesee(mode_fraude=True)

        elif choix == "c":
            envoyer_pesee(mode_fraude=False)

        elif choix == "":
            # Vague automatique
            nombre = random.randint(3, 6)
            index_fraude = random.randint(0, nombre - 1)
            print(f"\n🚛 Vague de {nombre} camions détectés...")

            for i in range(nombre):
                est_fraude = (i == index_fraude)
                envoyer_pesee(mode_fraude=est_fraude)
                if i < nombre - 1:
                    delai = random.uniform(1.5, 2.5)
                    print(f"  ⏱  Prochain camion dans {delai:.1f}s...")
                    time.sleep(delai)

            print(f"\n✅ Fin de vague. {nombre} pesées envoyées.")

        else:
            print("Commande inconnue. Entrée=vague, f=fraude, c=conforme, q=quitter")

if __name__ == "__main__":
    demarrer_simulation()
