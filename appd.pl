#!/usr/bin/perl -w

use LWP::UserAgent;
use HTTP::Request;
use appd;

$cfg = appd::newConfig();
print "Created config $cfg\n";
appd::appd_config_init($cfg);
print "Config init OK\n";

# set AppD SDK config
appd::set_app_name($cfg, "TestApp");
appd::set_tier_name($cfg, "Perl");
appd::set_node_name($cfg, "foobar");

appd::set_controller_host($cfg, "localhost");
appd::set_controller_port($cfg, 8090);
appd::set_controller_account($cfg, "customer1");
appd::set_controller_access_key($cfg, "6ca84575-ffec-470d-8099-9e527ade5033");
appd::set_controller_use_ssl($cfg, 0);
appd::set_init_timeout_ms($cfg, 0);

# Debug
appd::dump_config($cfg);
$rc = appd::appd_sdk_init($cfg);
print "SDK init $rc\n";

if($rc == 0) {
    # add a backend
    $backendname = "foobar";
    appd::appd_backend_declare($appd::APPD_BACKEND_HTTP, $backendname);
    $rc = appd::appd_backend_set_identifying_property($backendname, "HOST", "localhost");
    $rc = appd::appd_backend_set_identifying_property($backendname, "PORT", "8080");
    if($rc != 0) {
        die "Failed to set host on backend\n";
    }
    $rc = appd::appd_backend_add($backendname);
    if($rc != 0) {
        die "Failed to add backend\n";
    }
    # Loop through a BT a few times
    for($i = 1; $i <= 20; $i++) {
        print "Starting BT\n";
        $bt = appd::appd_bt_begin("foobar", "");
        print "BT started $bt\n";
        sleep(1);
        $exit = appd::appd_exitcall_begin($bt, $backendname);
        print "Exit call started $exit\n";
        # call HTTP backend
        $ua = LWP::UserAgent->new;
        $ua->agent("$0/0.1" . $ua->agent);
        $correlation = appd::appd_exitcall_get_correlation_header($exit);
        print "Correlation header $correlation\n";
        $req = new HTTP::Request 'GET', 'http://localhost:8080/TestApp/index.jsp';
        $req->header($appd::APPD_CORRELATION_HEADER_NAME => $correlation);
        $resp = $ua->request($req);
        if($resp->is_success) {
            $page = $resp->decoded_content;
            print "Got page\n";
        } else {
            print "Error " . $resp->status_line . "\n";
        }
        appd::appd_exitcall_end($exit);
        appd::appd_bt_end($bt);
        print "BT ended\n";
    }

    # The SDK does not like short running processes
    print "Wait before exit\n";
    sleep(60);
    appd::appd_sdk_term();
    print "The End\n\n";
}

exit;

