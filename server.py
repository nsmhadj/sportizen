import os
import socket
import threading
from datetime import datetime, timedelta

import psycopg2
import psycopg2.extras

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

HOST = "0.0.0.0"
PORT = 11000


def pg_conn():
    """
    Ouvre une connexion PostgreSQL en utilisant les variables d'environnement.

    Variables attendues :
        PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD, PGSSLMODE
    """
    return psycopg2.connect(
        host=os.getenv("PGHOST"),
        port=int(os.getenv("PGPORT", "5432")),
        dbname=os.getenv("PGDATABASE"),
        user=os.getenv("PGUSER"),
        password=os.getenv("PGPASSWORD"),
        sslmode=os.getenv("PGSSLMODE", "require"),
    )


def get_user_by_id(id_joueur: int):
    """Récupère un utilisateur par son id_utilisateur"""
    with pg_conn() as c, c.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        cur.execute(
            """
            SELECT id_utilisateur,
                   nom,
                   prenom,
                   mot_de_passe,
                   date_naissance
            FROM utilisateur
            WHERE id_utilisateur = %s
            """,
            (id_joueur,),
        )
        return cur.fetchone()


def team_exists_for_user(id_joueur: int, nom_equipe: str) -> bool:
    """
    Vérifie s'il existe une réservation pour ce joueur
    dans une équipe donnée, sur un match encore proposé.
    """
    with pg_conn() as c, c.cursor() as cur:
        cur.execute(
            """
            SELECT 1
            FROM reservation r
            JOIN equipe e          ON r.id_equipe = e.id_equipe
            JOIN match m           ON r.id_match = m.id_match
            JOIN match_propose mp  ON m.id_match = mp.id_match_p
            WHERE r.id_utilisateur = %s
              AND LOWER(e.nom) = LOWER(%s)
              AND (r.statut = 'confirmée' OR r.statut IS NULL)
            LIMIT 1
            """,
            (id_joueur, nom_equipe),
        )
        return cur.fetchone() is not None


def valider_qr(id_joueur: int, qr_value: str):
  
    with pg_conn() as c, c.cursor() as cur:
       
        cur.execute(
            """
            SELECT r.qr_etat, c.debut_ts, r.id_reservation FROM reservation r JOIN match m   ON r.id_match = m.id_match JOIN creneau c ON m.id_creneau = c.id_creneau
            WHERE r.id_utilisateur = %s AND r.qr_hash = %s AND (r.statut = 'confirmée' OR r.statut IS NULL)
            LIMIT 1
            """,
            (id_joueur, qr_value),
        )
        row = cur.fetchone()
        if not row:
            return False, "QR invalide ou non associe"
        qr_etat, debut_ts, id_res = row
        if qr_etat is not None and qr_etat.lower() != "actif":
            return False, "qr deja utilise"

       
        cur.execute(
            """
            UPDATE reservation SET qr_etat = 'inactif' WHERE id_reservation = %s
            """,
            (id_res,),
        )
    

        return True, None


def send_line(conn, msg: str):
    """Envoie une ligne terminée par \\n, sans planter si le client a coupé."""
    try:
        conn.sendall((msg + "\n").encode("utf-8"))
    except (BrokenPipeError, ConnectionResetError, ConnectionAbortedError, OSError):
        pass

def read_line(conn):
    """
    Lit une ligne terminée par \\n.
    Retourne None si la socket est fermée.
    """
    data = bytearray()
    try:
        while True:
            ch = conn.recv(1)
            if not ch:
                return None
            if ch == b"\n":
                break
            data += ch
        return data.decode("utf-8", errors="replace").strip()
    except (ConnectionAbortedError, ConnectionResetError, OSError):
        return None


def handle_client(sock, addr):
    try:
        print(f"[INFO] Nouvelle connexion depuis {addr}")

    
        line = read_line(sock)
        if not line or not line.startswith("ID_JOUEUR:"):
            send_line(sock, "ACCES REFUSE, MOTIF: format id invalide")
            return

        try:
            id_joueur = int(line.split(":", 1)[1].strip())
        except ValueError:
            send_line(sock, "ACCES REFUSE, MOTIF: id doit etre un entier")
            return

        user = get_user_by_id(id_joueur)
        if not user:
            send_line(sock, "ACCES REFUSE, MOTIF: joueur inconnu")
            return

        print(
            f"[INFO] Connexion de {user['prenom']} {user['nom']} "
            f"(ID {user['id_utilisateur']}) depuis {addr}"
        )

      
        db_date = user["date_naissance"]
        if db_date is None:
            send_line(sock, "ACCES REFUSE, MOTIF: date de naissance non definie en base")
            return

        db_date_str = db_date.strftime("%Y-%m-%d")
        MAX_ATTEMPTS = 2

        attempts_date = 0
        while attempts_date < MAX_ATTEMPTS:
            send_line(sock, "DATE_NAISSANCE:YYYY-MM-DD")
            line = read_line(sock)
            if line is None:
                send_line(sock, "ACCES REFUSE, MOTIF: connexion interrompue")
                return

            if not line.startswith("DATE_NAISSANCE:"):
                attempts_date += 1
                continue

            saisie_date = line.split(":", 1)[1].strip()
            if saisie_date == db_date_str:
                break
            else:
                attempts_date += 1

        if attempts_date >= MAX_ATTEMPTS:
            send_line(sock, "ACCES REFUSE, MOTIF: date de naissance incorrecte")
            return

      
        attempts_team = 0
        while attempts_team < MAX_ATTEMPTS:
            send_line(sock, "NOM_EQUIPE:?")
            line = read_line(sock)
            if line is None:
                send_line(sock, "ACCES REFUSE, MOTIF: connexion interrompue")
                return

            if not line.startswith("NOM_EQUIPE:"):
                attempts_team += 1
                continue

            nom_equipe = line.split(":", 1)[1].strip()
            if team_exists_for_user(id_joueur, nom_equipe):
                break
            else:
                attempts_team += 1

        if attempts_team >= MAX_ATTEMPTS:
            send_line(sock, "ACCES REFUSE, MOTIF: aucune reservation active pour cette equipe")
            return

   
        send_line(sock, "QR_CODE:?")
        line = read_line(sock)
        if line is None or not line.startswith("QR_CODE:"):
            send_line(sock, "ACCES REFUSE, MOTIF: qr manquant ou format invalide")
            return

        qr_value = line.split(":", 1)[1].strip()

        ok, motif = valider_qr(id_joueur, qr_value)
        if not ok:
            send_line(sock, f"ACCES REFUSE, MOTIF: {motif}")
            return

       
        send_line(sock, "ACCES AUTORISE")

    except Exception as e:
        print(f"[ERREUR] {e}")
        try:
            send_line(sock, "ACCES REFUSE, MOTIF: erreur interne")
        except Exception:
            pass
    finally:
        try:
            sock.close()
        except Exception:
            pass
        print(f"[INFO] Connexion fermee pour {addr}")


def main():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((HOST, PORT))
        s.listen(5)
        print(f"Serveur en ecoute sur {HOST}:{PORT}")
        while True:
            conn, addr = s.accept()
            threading.Thread(
                target=handle_client,
                args=(conn, addr),
                daemon=True,
            ).start()


if __name__ == "__main__":
    main()
