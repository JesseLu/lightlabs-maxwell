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

    static final String controlCert = "-----BEGIN CERTIFICATE-----\nMIIClDCCAf2gAwIBAgIJAJQjiY9rIng/MA0GCSqGSIb3DQEBBQUAMGMxCzAJBgNV\nBAYTAlVTMQswCQYDVQQIDAJDQTEhMB8GA1UECgwYSW50ZXJuZXQgV2lkZ2l0cyBQ\ndHkgTHRkMSQwIgYDVQQDDBttYXh3ZWxsLXNlcnZlci5saWdodGxhYnMuY28wHhcN\nMTMwMTE1MjAyMDAxWhcNMTQwMTE1MjAyMDAxWjBjMQswCQYDVQQGEwJVUzELMAkG\nA1UECAwCQ0ExITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDEkMCIG\nA1UEAwwbbWF4d2VsbC1zZXJ2ZXIubGlnaHRsYWJzLmNvMIGfMA0GCSqGSIb3DQEB\nAQUAA4GNADCBiQKBgQC47cFrtn3eZ9Y2rMwggWAtH6cVwjFyZEQo34fUBid81lr0\ntXIe72sujjB27KYInvf/ymLIDfmh5n4WqnUkOF39Mc4QQv0mLnzMnuJZnZBQl5mR\nDyA5LBYkeIPa4Z1azEUXlch5XlyGE/AVhsJYWrYQHnR5tYRwQw/ndtaJk2fvPwID\nAQABo1AwTjAdBgNVHQ4EFgQUbAYSQlW2B7r2Qtbe3C5AZAJjBgwwHwYDVR0jBBgw\nFoAUbAYSQlW2B7r2Qtbe3C5AZAJjBgwwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0B\nAQUFAAOBgQAoSq8AyT7WHEqKGZ7eYeEBBCNqR/Aa4ZKo8hL9mSCuADYZkkhcAGTG\ni4edoVtGZlFUhS+3T2pgWua/w+BQVz4HJ4UyFIWCK4cvAbcf5/QyFY/e9gJNuQBF\nP5S6kZNg059CHppV5T1u+cg3qZMZ/fvO8+ImwoHqD15/xuvQEHyXbQ==\n-----END CERTIFICATE-----";


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
    store.setCertificateEntry("maxwell-control", certificate);

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
