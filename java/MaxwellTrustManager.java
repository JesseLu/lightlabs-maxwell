import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509TrustManager;
import java.security.cert.X509Certificate;
import java.security.cert.CertificateException;
import java.security.cert.Certificate;
import java.security.cert.CertificateFactory;
import java.security.KeyStore;
import java.io.IOException;
import java.io.InputStream;
import java.io.ByteArrayInputStream;

public class MaxwellTrustManager {

    static final String controlCert = "-----BEGIN CERTIFICATE-----\nMIICojCCAgugAwIBAgIJAIg2cJJQyMSEMA0GCSqGSIb3DQEBBQUAMGoxCzAJBgNV\nBAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX\naWRnaXRzIFB0eSBMdGQxIzAhBgNVBAMMGm1hc3Rlci1zZXJ2ZXIubGlnaHRsYWJz\nLmNvMB4XDTEzMDExNTIwNDA1MFoXDTE0MDExNTIwNDA1MFowajELMAkGA1UEBhMC\nQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoMGEludGVybmV0IFdpZGdp\ndHMgUHR5IEx0ZDEjMCEGA1UEAwwabWFzdGVyLXNlcnZlci5saWdodGxhYnMuY28w\ngZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBALdT8SDiXR4/nGIiY3ENHWYp9un3\nNTljT99VHOuv5BKRAnOWWwFVGbue2pqlugLv63Xk5vq2TL7MICav7zAodcgEgvPP\nDCoCLTgl7pYlNjjByHHOTV9x/c93G3hy79gWYxhFrniLlf6PSiH+aOxi5JG0AvBh\nxtmjFl96IUMzFy2HAgMBAAGjUDBOMB0GA1UdDgQWBBQxg1ZohhqsIzRQL/2fdUrl\ne9TrnTAfBgNVHSMEGDAWgBQxg1ZohhqsIzRQL/2fdUrle9TrnTAMBgNVHRMEBTAD\nAQH/MA0GCSqGSIb3DQEBBQUAA4GBAEZOFz75eZS8clXdqPR6aoj7fA5xMblFKsrF\nUGaOPq1MZv3WxULowrZ+D6GnO8X30ctb4sCjZ0qVPqQCtvuiuUC5gSbO5cEam1hN\nfjp3MMNkBlVW55Hau0ZNjTJvKYmM9ttXL/D15tIZEl1X5Mu8s+kLDSS4u2KQRr+H\nsrrD6D+n\n-----END CERTIFICATE-----";


    static public TrustManager[] getManager() throws Exception {
        // Create a trust manager that does not validate certificate chains
        TrustManager[] trustAllCerts = new TrustManager[]
                                        {new MyTrustManager(controlCert)};
        return trustAllCerts;
    }

    static public TrustManager[] getManager(String cert) throws Exception {
        // Create a trust manager that does not validate certificate chains
        TrustManager[] trustAllCerts = new TrustManager[]{new MyTrustManager(cert)};
        return trustAllCerts;
    }
}

class MyTrustManager implements X509TrustManager {
    private final X509TrustManager trustManager;

    public MyTrustManager(String cert) throws Exception {

    // Load a KeyStore with only our certificate
    KeyStore store = KeyStore.getInstance(KeyStore.getDefaultType());
    store.load(null, null);
    Certificate certificate = loadPemCert(cert);
    store.setCertificateEntry("maxwell-server", certificate);

    // create a TrustManager using our KeyStore
    TrustManagerFactory factory = TrustManagerFactory.getInstance(
        TrustManagerFactory.getDefaultAlgorithm());
    factory.init(store);
    this.trustManager = getX509TrustManager(factory.getTrustManagers());
    }

    public void checkClientTrusted(X509Certificate[] chain, String authType)
      throws CertificateException {
    trustManager.checkClientTrusted(chain, authType);
    }

    public void checkServerTrusted(X509Certificate[] chain, String authType)
      throws CertificateException {
    trustManager.checkServerTrusted(chain, authType);
    }

    public X509Certificate[] getAcceptedIssuers() {
    return trustManager.getAcceptedIssuers();
    }

    private static X509TrustManager getX509TrustManager(TrustManager[] managers) {
    for (TrustManager tm : managers) {
      if (tm instanceof X509TrustManager) {
        return (X509TrustManager) tm;
      }
    }
    return null;
    }

    private Certificate loadPemCert(String cert) 
      throws CertificateException, IOException {
//     InputStream stream = 
//       this.getClass().getClassLoader().getResourceAsStream("server.pem");
    InputStream stream = new ByteArrayInputStream(cert.getBytes("ASCII"));
    CertificateFactory factory = CertificateFactory.getInstance("X.509");
    return factory.generateCertificate(stream);
    }
}
