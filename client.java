import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.util.Scanner;

public class client {
//connexion avec server applicatif sur localhost port 11000 
    private static final String HOST = "127.0.0.1"; 
    private static final int PORT = 11000;

    public static void main(String[] args) {
        try (
                Socket socket = new Socket(HOST, PORT);
                PrintWriter out = new PrintWriter(socket.getOutputStream(), true);
                BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
                Scanner scanner = new Scanner(System.in)
        ) {
            System.out.println("Connexion au serveur " + HOST + ":" + PORT);

          
            System.out.print("Entrez votre ID_JOUEUR: ");
            String id = scanner.nextLine().trim();
            out.println("ID_JOUEUR:" + id);

            String line;
            while ((line = in.readLine()) != null) {
               
                System.out.println("SERVEUR: " + line);

      
                if (line.startsWith("ACCES AUTORISE") || line.startsWith("ACCES REFUSE")) {
                    break;
                }

                if (line.startsWith("DATE_NAISSANCE:")) {
                    System.out.print("Entrez votre date de naissance (YYYY-MM-DD): ");
                    String date = scanner.nextLine().trim();
                    out.println("DATE_NAISSANCE:" + date);
                }
              
                else if (line.equals("NOM_EQUIPE:?")) {
                    System.out.print("Entrez le nom de votre equipe: ");
                    String nomEquipe = scanner.nextLine().trim();
                    out.println("NOM_EQUIPE:" + nomEquipe);
                }
       
                else if (line.equals("QR_CODE:?")) {
                    System.out.print("Scannez / entrez le QR code: ");
                    String qr = scanner.nextLine().trim();
                    out.println("QR_CODE:" + qr);
                }
            }

            System.out.println("Fin de la communication avec le serveur.");

        } catch (IOException e) {
            System.err.println("Erreur client: " + e.getMessage());
        }
    }
}
