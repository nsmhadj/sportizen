import java.io.*;
import java.net.*;
import java.util.Locale;
import java.util.Scanner;

public class client {
    public static void main(String[] args) {
        String serverAddress = "localhost";
        int port = 11000; 

        try (
            Socket socket = new Socket(serverAddress, port);
            PrintWriter writer = new PrintWriter(socket.getOutputStream(), true);
            BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()));
            Scanner scanner = new Scanner(System.in)
        ) {
            System.out.println(" Connexion au serveur établie.");
            System.out.println("------------------------------------");

            // === Étape 1 : ID joueur ===
            System.out.print("Entrez l'ID du joueur : ");
            String idJoueur = scanner.nextLine().trim();
            writer.println("ID_JOUEUR:" + idJoueur);

            String response = reader.readLine();
            System.out.println("SERVEUR : " + response);
            if (response == null) return;

            // Demande mot de passe 
            String r1 = response.toLowerCase(Locale.ROOT);
            if (r1.contains("mot de passe")) {
                System.out.print("Entrez le mot de passe : ");
                String motDePasse = scanner.nextLine().trim();
                writer.println("MOT_DE_PASSE:" + motDePasse);

                response = reader.readLine();
                System.out.println("SERVEUR : " + response);
                if (response == null) return;

                // Demande QR 
                String r2 = response.toLowerCase(Locale.ROOT);
                if (r2.contains("qr")) { 
                    System.out.print("Scannez / entrez le code QR : ");
                    String qr = scanner.nextLine().trim();
                    writer.println("QR_CODE:" + qr);

                    response = reader.readLine();
                    System.out.println("SERVEUR : " + response);
                } else if (r2.contains("tentative 1/2")) {

                 System.out.print("reessayer le mot de passe : ");
                motDePasse = scanner.nextLine().trim();
                writer.println("MOT_DE_PASSE:" + motDePasse);
                 response = reader.readLine();
    System.out.println("SERVEUR : " + response);
    if (response == null) return;
                String r3 = response.toLowerCase(Locale.ROOT);
                if (r3.contains("qr")) { 
                    System.out.print("Scannez / entrez le code QR : ");
                    String qr = scanner.nextLine().trim();
                    writer.println("QR_CODE:" + qr);
                    response = reader.readLine();
                    System.out.println("SERVEUR : " + response);
                } else {
                   System.out.println("tentative 2 echouée , compte bloqué"); 
                }
            }
             else {
            
             }}

            System.out.println("------------------------------------");
            System.out.println("Session terminée.");
        } catch (IOException e) {
            System.out.println(" Erreur de connexion au serveur : " + e.getMessage());
        }
    }
}
