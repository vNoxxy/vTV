package io.github.vnoxxy.vtv.site;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.widget.Toast;

/** Ouvre le site de cette tuile dans Chrome, ou à défaut dans le navigateur du boîtier. */
public class OuvrirSite extends Activity {
    // Chrome plutôt qu'une WebView maison : il bloque les fenêtres surgissantes et se met à jour seul.
    private static final String CHROME = "com.android.chrome";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Intent voir = new Intent(Intent.ACTION_VIEW, Uri.parse(getString(R.string.site_url)))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        try {
            startActivity(new Intent(voir).setPackage(CHROME));
        } catch (ActivityNotFoundException sansChrome) {
            try {
                startActivity(voir);
            } catch (ActivityNotFoundException sansNavigateur) {
                Toast.makeText(this, R.string.sans_navigateur, Toast.LENGTH_LONG).show();
            }
        }
        // Theme.NoDisplay demande de finir avant onResume.
        finish();
    }
}
