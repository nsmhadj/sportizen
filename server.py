# serveur_scenario.py
import socket
import threading
from datetime import datetime, timedelta

HOST = "localhost"
PORT = 11000

# --- Données simulées (à adapter) ---
players = {
    "158": {"password": "1234", "status": "actif", "reservations": [401]},
    "200": {"password": "0000", "status": "actif", "reservations": []},  # pas de résa
}

# match 401: 17:00–19:00 aujourd'hui (fenêtre -30min / +15min)
now = datetime.now()
match_start = now.replace(hour=22, minute=30, second=0, microsecond=0)
match_end   = now.replace(hour=19, minute=0, second=0, microsecond=0)
matches = {
    401: {"start": match_start, "end": match_end}
}

tickets = {
    "ABC123XYZ": {"joueur_id": "158", "match_id": 401, "used": False, "active": True},
    "ZED900AAA": {"joueur_id": "158", "match_id": 401, "used": True,  "active": True},  # déjà utilisé
}

GRACE_BEFORE_MIN = 30  # entrée possible 30 min avant
GRACE_AFTER_MIN  = 15  # et 15 min après le début

# --- Utilitaires ---
def send_line(conn, text: str):
    conn.sendall((text + "\n").encode("utf-8"))

def read_line(conn) -> str:
    data = b""
    while not data.endswith(b"\n"):
        chunk = conn.recv(1)
        if not chunk:
            break
        data += chunk
    return data.decode("utf-8").rstrip("\r\n")

def in_window(t_scan: datetime, start: datetime, end: datetime) -> bool:
    early = start - timedelta(minutes=GRACE_BEFORE_MIN)
    late  = start + timedelta(minutes=GRACE_AFTER_MIN)
    # Option: on refuse après la fin du match
    hard_end = max(late, end)
    return early <= t_scan <= hard_end

# --- Dialogue par client ---
def handle_client(conn, addr):
    print(f"[+] Client connecté: {addr}")
    try:
        # Étape 1: attendre ID_JOUEUR
        line = read_line(conn)
        if not line or not line.startswith("ID_JOUEUR:"):
            send_line(conn, "Format invalide: attendu ID_JOUEUR:<id>")
            return

        id_joueur = line.split(":", 1)[1].strip()
        joueur = players.get(id_joueur)

        # Vérif joueur
        if joueur is None or joueur.get("status") != "actif":
            send_line(conn, "Joueur introuvable ou inactif")
            return

        # Vérif réservation pour un match (exemple: 401)
        target_match_id = 401
        if target_match_id not in joueur.get("reservations", []):
            send_line(conn, "Aucune réservation active pour ce match")
            return

        # Demander mot de passe
        send_line(conn, "Joueur trouvé, veuillez entrer le mot de passe")

        # Étape 2: mot de passe (2 essais)
        ok_pwd = False
        for attempt in range(1, 4):
            line = read_line(conn)
            if not line or not line.startswith("MOT_DE_PASSE:"):
                send_line(conn, f"Format invalide: attendu MOT_DE_PASSE:<valeur> (essai {attempt}/2)")
                continue
            pwd = line.split(":", 1)[1].strip()
            if pwd == joueur["password"]:
                ok_pwd = True
                break
            else:
                if attempt < 3 :
                    send_line(conn, f"Mot de passe erroné, tentative {attempt}/2")
                else:
                    send_line(conn, "Compte bloqué après 2 tentatives")
        if not ok_pwd:
            return
        send_line(conn, "Mot de passe conforme, veuillez scanner le code QR")

        # Étape 3: QR_CODE
        line = read_line(conn)  
        if not line or not line.startswith("QR_CODE:"):
            send_line(conn, "Format invalide: attendu QR_CODE:<code>")
            return
        qr_code = line.split(":", 1)[1].strip()

        ticket = tickets.get(qr_code)
        if ticket is None:
            send_line(conn, "QR code invalide, accès refusé")
            return
        if not ticket.get("active", False):
            send_line(conn, "QR inactif/annulé, accès refusé")
            return
        if ticket.get("used", False):
            send_line(conn, "QR déjà utilisé, accès refusé")
            return
        if ticket["joueur_id"] != id_joueur:
            send_line(conn, "QR non associé à ce joueur, accès refusé")
            return
        if ticket["match_id"] != target_match_id:
            send_line(conn, "QR non valable pour ce match, accès refusé")
            return

        # Vérif fenêtre horaire
        tscan = datetime.now()
        m = matches.get(ticket["match_id"])
        if not m or not in_window(tscan, m["start"], m["end"]):
            send_line(conn, "Hors fenêtre horaire, accès refusé")
            return

        # Commit: marquer utilisé
        ticket["used"] = True
        send_line(conn, "Accès autorisé, ouverture porte")

    except Exception as e:
        print(f"[!] Erreur côté serveur: {e}")
        try:
            send_line(conn, "Erreur serveur, réessayez plus tard")
        except Exception:
            pass
    finally:
        conn.close()
        print(f"[-] Client déconnecté: {addr}")

def main():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((HOST, PORT))
        s.listen(5)
        print(f"Serveur démarré sur {HOST}:{PORT} — prêt pour le client Java")

        while True:
            conn, addr = s.accept()
            threading.Thread(target=handle_client, args=(conn, addr), daemon=True).start()

if __name__ == "__main__":
    main()
