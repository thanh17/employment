import org.apache.hc.client5.http.classic.methods.HttpGet;
import org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import org.apache.hc.client5.http.impl.classic.CloseableHttpResponse;
import org.apache.hc.client5.http.impl.classic.HttpClients;
import org.apache.hc.core5.http.HttpEntity;
import org.apache.hc.core5.http.ParseException;
import org.apache.hc.core5.http.io.entity.EntityUtils;
import org.apache.hc.core5.net.URIBuilder;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;

public class CareerOneStopAPISample {
    public static void main(String[] args) throws IOException, URISyntaxException {
        URI uri = new URIBuilder()
                .setScheme("https")
                .setHost("api.careeronestop.org")
                .setPath("/v1/skillgap/{userId}/{onetCodeSource}/{onetCodeTarget}/{location}/{radius}")
                .build();
        CloseableHttpResponse response = null;
        HttpGet httpGet = null;
        try {
            CloseableHttpClient httpClient = HttpClients.createDefault();
            httpGet = new HttpGet(uri);
            httpGet.setHeader("Content-Type","application/json");
            httpGet.setHeader("Authorization", "Bearer API Token");
            response = httpClient.execute(httpGet);
            HttpEntity entity = response.getEntity();
            System.out.println(EntityUtils.toString(entity));
        } catch (ParseException e) {
            e.printStackTrace();
        } finally {
//            if(httpGet != null) httpGet.releaseConnection();
            if(response != null) response.close();
        }
    }
}