# README-DETOX — Detox OS content-pipeline i MoneyPrinterTurbo

Dette dokumentet beskriver hvordan denne forken av MoneyPrinterTurbo brukes
til å generere faceless kortvideoer (TikTok/Shorts/Reels) som markedsfører
Detox OS, med innhold grunnet i `MindMatter1444/detox-foundation`.

Skrevet 2026-08-20 etter oppdrag fra Orion (`START-HERE-moneyprinterturbo-detox-2026-08-19.md`).

---

## 1. Hva er allerede gjort

| Leveranse | Status |
| :--- | :--- |
| `detox_topics.txt` | ✅ 20 temaer, hvert grunnet i en spesifikk `status: approved`-fil i detox-foundation |
| `config.toml` | ✅ Opprettet fra `config.example.toml`, LLM satt til DeepSeek via MindMatter sin LiteLLM-proxy |
| `run_detox_batch.sh` | ✅ Wrapper-script — cli.py har ingen innebygd batch-fra-fil-modus, så dette scriptet looper over `detox_topics.txt` |
| API-nøkler | ⚠️ Delvis — se seksjon 3, flere mangler |
| Buffer/TikTok/Shorts-kobling | ⚠️ Ikke bygget — se seksjon 5, ingen native Buffer-integrasjon finnes i MoneyPrinterTurbo |
| Freya-integrasjon | ⚠️ Ikke bygget — se seksjon 6 |

---

## 2. Hvordan kjøre MoneyPrinterTurbo med Detox-temaer

### Forutsetning: SSH-tunnel til LiteLLM-proxyen

MindMatter sin LiteLLM-proxy (`litellm.service`) kjører på Hetzner-serveren
(`157.180.126.233`) og lytter **kun på `127.0.0.1:4000`** på den maskinen —
den er ikke eksponert utad. `config.toml` her peker på `127.0.0.1:4000`, som
betyr at MoneyPrinterTurbo enten må:

- **kjøre direkte på Hetzner-serveren**, eller
- **kjøre lokalt (som nå, i WSL) med en SSH-tunnel åpen**:

  ```bash
  ssh -i ~/.ssh/hetzner_frihetsfabrikken -N -L 4000:127.0.0.1:4000 root@157.180.126.233
  ```

  La denne kjøre i egen terminal/tmux-sesjon mens du genererer videoer.

Dette er ikke verifisert i praksis i denne økten (ingen faktisk videogenerering
er kjørt) — kun konfigurert og lest fra kildekoden. Se seksjon 7 for hva som
gjenstår å teste.

### Kjør ett enkelt tema

```bash
cd /home/adrian/MoneyPrinterTurbo
uv run python cli.py \
  --video-subject "Hos Detox kommer mennesket før systemet — alltid" \
  --video-language nb-NO \
  --voice-name nb-NO-PernilleNeural-Female \
  --video-aspect 9:16
```

`--video-aspect 9:16` gir portrettformat (TikTok/Shorts/Reels). Legg til
`--stop-at script` for å bare generere manus og stoppe der — nyttig for å
kvalitetssikre teksten før video/TTS genereres (se seksjon 4 om redaksjonell
kontroll).

### Kjør hele `detox_topics.txt` som batch

```bash
cd /home/adrian/MoneyPrinterTurbo
./run_detox_batch.sh
```

Ekstra flagg legges bakerst og sendes videre til `cli.py`, f.eks.:

```bash
./run_detox_batch.sh --stop-at script   # kun manus, ikke full video, for alle 20 temaene
```

Output havner i `./storage/` (standard `material_directory` i
`config.example.toml` — ikke endret i `config.toml`).

---

## 3. API-nøkler — status

| Nøkkel | Trengs til | Status |
| :--- | :--- | :--- |
| `deepseek_api_key` (LiteLLM-nøkkel) | Manusgenerering (LLM) | ❌ **Mangler.** `config.toml` har placeholder `REPLACE_WITH_LITELLM_VIRTUAL_KEY`. Jeg har **ikke** opprettet en ny virtual key på produksjons-LiteLLM-proxyen uten Adrians godkjenning — dette er en endring på delt infrastruktur. **[KREVER GODKJENNING]**: enten få Adrian til å opprette en scoped virtual key for MoneyPrinterTurbo, eller få master-key-verdien overlevert utenfor chat. |
| `pexels_api_keys` | Videomateriale (stock-klipp) | ❌ **Mangler.** Gratis å registrere på pexels.com/api. `video_source = "pexels"` er satt som standard i `config.example.toml`/`config.toml`. |
| TTS (tale) | Norsk voiceover | ✅ **Trengs ikke.** `subtitle_provider = "edge"` og `nb-NO-PernilleNeural-Female` (Edge TTS) er gratis, ingen nøkkel kreves. Bekreftet i `app/services/data/azure_voices.json` — to norske stemmer finnes: `nb-NO-FinnNeural` (mann) og `nb-NO-PernilleNeural` (kvinne). |
| `pixabay_api_keys` / `coverr_api_keys` | Alternative videokilder | Ikke satt — kun nødvendig hvis Pexels ikke dekker behovet |
| `upload_post_api_key` | Automatisk publisering til TikTok/IG/YouTube | ❌ Mangler, og ikke anbefalt satt opp før seksjon 5 er avklart med Adrian |

**Modellvalg-avvik funnet under research (ikke fabrikkert, verifisert mot
faktisk `/root/mindmatter/litellm-config.yaml` på Hetzner):** Det finnes ingen
modell-alias literally kalt "nous" i LiteLLM-configen. DeepSeek V4 Pro rutes i
dag via OpenRouter under aliasene `orion-xai` og `orion-coder` (begge peker på
`openrouter/deepseek/deepseek-v4-pro`) — historiske navn fra da ruting gikk
via xAI. `orion-coder` er brukt i `config.toml` her. **Åpent punkt for Orion/
Adrian:** bør det opprettes en tydelig navngitt alias (f.eks. `detox-content`)
i stedet for å gjenbruke `orion-coder`?

---

## 4. Redaksjonell kontroll (obligatorisk, ikke valgfritt)

`detox_topics.txt` er bevisst holdt på et trygt, ikke-helsepåstående nivå
(se filens header-kommentar). Men **LLM-generert manus fra disse temaene er
likevel ikke automatisk godkjent Detox-kunnskap.** Per
`010-agent-constitution.md` (publiseringsnivå-tabellen) krever "utdannende
innhold" (P2) menneskelig redaksjonell kontroll før publisering, og
`008-customer-philosophy.md` sin kanalmatrise sier eksplisitt at sosiale
medier/markedsføring krever varsomhet mot helsepåstander, frykt og
før/etter-fortellinger.

Anbefalt flyt: generer manus med `--stop-at script`, få Kim/Anniken (eller
utpekt redaksjonell eier) til å lese og godkjenne teksten, **deretter** kjør
full videogenerering på det godkjente manuset via `--video-script`.

---

## 5. Hvordan output kobles til Buffer/TikTok/Shorts

**Ikke bygget i denne økten — kun kartlagt.** MoneyPrinterTurbo har ingen
innebygd Buffer-integrasjon (verifisert: ingen treff på "buffer" som
tjenestenavn i kildekoden). To reelle veier finnes:

1. **`upload_post.com`-integrasjonen som allerede finnes i appen**
   (`upload_post_enabled`, `upload_post_platforms = ["tiktok", "instagram"]`
   i `config.example.toml`). Dette er en betalt tredjepartstjeneste, ikke
   Buffer, og krever egen API-nøkkel og kontovalidering. Ikke aktivert i
   `config.toml` her.
2. **Manuell/eksisterende Freya→Buffer-pipeline.** Mind Matter har fra før en
   fungerende Content Pipeline v1 (Freya → Buffer, E2E verifisert i tidligere
   sesjon). Den mest sannsynlige veien er å la ferdige MP4-filer fra
   `./storage/` legges inn i samme intake-mekanisme som den pipelinen
   allerede bruker, i stedet for å bygge en ny direkte-til-TikTok-vei her.
   **Jeg har ikke verifisert i denne økten hvordan den pipelinens intake
   faktisk fungerer** (repo/mappe ikke undersøkt her) — dette er et åpent
   punkt, ikke en antakelse jeg har testet.

**Anbefaling:** avklar med Adrian om (1) eller (2) er ønsket retning før noe
bygges videre.

---

## 6. Freya-integrasjon (temaoppdagelse)

**Ikke bygget.** Tiltenkt flyt per oppdraget: Freya oppdager nye
Detox-relevante temaer (f.eks. fra kundespørsmål, forskning eller nytt
foundation-innhold) → nye linjer legges til i `detox_topics.txt` i samme
format (`# Fra <kildefil>` + tema-linje).

For at dette skal være trygt må to ting på plass først:
- Freya må ha lesetilgang til `detox-foundation`-repoet for å kunne sitere
  riktig kildefil (ikke dikte opp en kilde).
- Nye temaer bør gå gjennom samme "kun `status: approved`"-sjekk som er brukt
  i denne økten, ikke legges til automatisk uten kontroll.

Dette er ikke implementert — kun beskrevet som forutsetning for senere arbeid.

---

## 7. Hva som gjenstår / ikke er verifisert

- **Ingen faktisk video er generert.** SSH-tunnel, LiteLLM-nøkkel og
  Pexels-nøkkel mangler, så `run_detox_batch.sh` er ikke kjørt ende-til-ende.
- Manusgenerering (kun LLM-kallet, med `--stop-at script`) bør testes først
  når LiteLLM-nøkkelen er på plass — det er den billigste og raskeste måten
  å verifisere at DeepSeek-ruting via LiteLLM faktisk fungerer fra
  MoneyPrinterTurbo.
- Buffer/TikTok-publisering (seksjon 5) og Freya-integrasjon (seksjon 6) er
  begge åpne punkter som krever et eget, avgrenset oppdrag.
- `orion-coder`-alias-navngivningen (seksjon 3) bør avklares med Orion.

---

## 8. Filer i denne leveransen

- `detox_topics.txt` — 20 videotemaer, kildesporet til detox-foundation
- `config.toml` — DeepSeek via LiteLLM, `git`-ignorert (ligger ikke i historikken)
- `run_detox_batch.sh` — batch-wrapper rundt `cli.py`
- `README-DETOX.md` — denne filen
