# Agenti AI e difese Linux — Linux Day 2026

[Scarica le slide in PDF](linux-day-sputnix-2026.pdf).

Le regole scritte nel prompt o nei file del progetto sono indicazioni, non confini di sicurezza: un agente può ignorarle o aggirarle. Le contromisure efficaci si sommano ai livelli del sistema operativo.

## Script di demo Fedora

- `scripts/linuxday-demo1.sh` prepara e avvia la scena senza difese.
- `scripts/linuxday-demo2.sh` ricrea `/work`, configura rete, audit e snapshot Btrfs, poi avvia la scena protetta.
- `scripts/linuxday-kill-players.sh` termina i processi demo e riavvia `fapolicyd` se risulta fermo.

> **Solo per una VM Fedora usa-e-getta, come root.** Il primo script ricrea i dati di `/home/demo`; il secondo può cancellare e ricreare `/work` e lo snapshot, modifica le regole Audit e installa `/etc/sudoers.d/linuxday-demo`. Non eseguirli su una macchina con dati reali.

## Quattro livelli di contromisura

1. **Contenimento:** esegui l’agente in un container rootless, montando solo il workspace; SELinux limita ulteriormente accessi e danni anche se il processo è ingannato.
2. **Rete in uscita:** nega l’accesso diretto a Internet; se serve parlare col modello, usa una rete interna e un proxy con allowlist, che custodisce le credenziali.
3. **Software fidato:** `fapolicyd` applica sull’host una policy di esecuzione; firme dei pacchetti e versioni/hash bloccati riducono il rischio di codice non verificato. `fapolicyd` sull’host non filtra i processi dentro il container.
4. **Rilevamento e recupero:** `auditd` registra le operazioni e `ausearch` aiuta a ricostruirle; snapshot Btrfs del workspace permettono un rollback rapido. Uno snapshot non sostituisce un backup fuori macchina, con ripristino verificato.

## Cercare gli eventi con `ausearch`

Prima si carica una regola Audit con una chiave, per esempio `agente`; poi si cercano gli eventi associati e si interpretano i campi:

```bash
sudo ausearch -k agente --interpret
```

La chiave va configurata nella regola di audit prima di avviare l’agente; altrimenti gli eventi non saranno associati a `agente`.

## Btrfs: snapshot e `btrfs restore`

Per il rollback dimostrato nel talk si usa un subvolume dedicato e uno snapshot in sola lettura; dopo aver rimosso il subvolume danneggiato, si crea un nuovo subvolume dallo snapshot. Non si usa `btrfs restore` per questo caso.

`btrfs restore` serve invece a recuperare file da un filesystem Btrfs danneggiato, copiandoli in una directory di destinazione senza modificare l’immagine sorgente. Si può prima fare una prova (`-D`):

```bash
sudo btrfs restore -D /dev/DEVICE /mnt/recovery
sudo btrfs restore /dev/DEVICE /mnt/recovery
```

Sostituisci `/dev/DEVICE` e `/mnt/recovery` con il dispositivo e la destinazione corretti; verifica con attenzione sorgente e destinazione prima del recupero.

## Approfondimenti

- [Podman `run` — container e opzioni di isolamento](https://docs.podman.io/en/latest/markdown/podman-run.1.html)
- [SELinux — guida Fedora](https://docs.fedoraproject.org/en-US/quick-docs/selinux-getting-started/)
- [seccomp — filtri sulle system call (documentazione del kernel)](https://docs.kernel.org/userspace-api/seccomp_filter.html)
- [Landlock — controllo degli accessi non privilegiato (documentazione del kernel)](https://docs.kernel.org/userspace-api/landlock.html)
- [fapolicyd — whitelist e policy di esecuzione](https://github.com/linux-application-whitelisting/fapolicyd)
- [`ausearch(8)` — ricerca nei log Audit](https://man7.org/linux/man-pages/man8/ausearch.8.html)
- [`btrfs subvolume(8)` — subvolumi e snapshot](https://man7.org/linux/man-pages/man8/btrfs-subvolume.8.html)
- [`btrfs restore(8)` — recupero di file da un filesystem danneggiato](https://man7.org/linux/man-pages/man8/btrfs-restore.8.html)
- [bootc — immagini OCI per aggiornamenti del sistema operativo](https://bootc-dev.github.io/bootc/)
- [Falco — rilevamento runtime](https://falco.org/docs/)
