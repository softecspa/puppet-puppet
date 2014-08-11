puppet-puppet
=============

....

puppet module

Configurazione di Puppet

Al momento la puppet configura l'agent sui nodi

Le classi puppet::master e puppet::puppedb sono in corso di sviluppo e configurano
i rispettivi ruoli.

L'esecuzione dell'agent viene disabilitata se attiva e l'agent viene eseguito
mediante una chiamata in cron.

L'agent viene eseguito nel wrapper puppet-run che si assicura di rieseguire il puppet
fino a che non viene eseguito senza errori.

N.B. Alla fine dell'esecuzione del puppet da parte del puppet-run viene scritto un file
in /usr/local/etc/motd.d per notificare a chi si logga quando e' stato eseguito l'ultima
volta il puppet. Il puppet-run è astuto e se la directory non c'e' non scrive il file, in
questo modo non c'e' una dipendenza tra questo modulo e il modulo motd.
