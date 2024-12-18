# Log Forwarding

## Windows via NXLog

Video: [Deutsch](https://www.youtube.com/watch?v=aV6HcEUsLqQ)

1. Install NXLog:

   [NXLog Community Download](https://nxlog.co/downloads/nxlog-ce#nxlog-community-edition)

2. Certificates:

   Add the certificate files to `C:\Program Files\nxlog\cert`

   Remove default-user access to the directory.

3. Configure NXLog:

   Edit the configuration file: `C:\Program Files\nxlog\conf\nxlog.conf`

   Base configuration example: [GELF TLS](https://github.com/O-X-L/logserver-graylog/blob/main/clients/nxlog_gelf_tls.conf)

   QueryList examples:

   * [Windows Server](https://github.com/O-X-L/logserver-graylog/blob/main/clients/nxlog_querylist_example_server.xml)
   * [Windows Clients](https://github.com/O-X-L/logserver-graylog/blob/main/clients/nxlog_querylist_example_client.xml)

4. Restart the `nxlog` service

Event Logs to monitor:

* [Graylog Blog](https://graylog.org/post/critical-windows-event-ids-to-monitor/)

----

## Linux via Rsyslog

Video: [Deutsch](https://www.youtube.com/watch?v=_jM_NZhUaew)

1. Install:

   `apt install rsyslog`

2. For encrypted forwarding:

   `apt install rsyslog-gnutls`

3. Add the certificates to the system

4. Add config to `/etc/rsyslog.d/`

   [TLS encrypted](https://github.com/O-X-L/logserver-graylog/blob/main/client/rsyslog_tls.conf) or [TCP unencrypted](https://github.com/O-X-L/logserver-graylog/blob/main/client/rsyslog_tcp.conf)

5. Activate it:

   `systemctl restart rsyslog.service`
