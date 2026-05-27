# CI/CD (GitHub Actions) — mobile-fila-facil

Arquivos criados:

- `.github/workflows/pr.yml` — valida testes unitários e builda o app em PRs.
- `.github/workflows/main.yml` — valida testes, builda e distribui o Android AAB para Firebase App Distribution quando houver push na `main`.

Segredos exigidos (configure em Settings → Secrets & variables → Actions):

- `FIREBASE_TOKEN`: token gerado com `firebase login:ci`. Usado pelo `firebase-tools` para autenticar na Action.
- `FIREBASE_ANDROID_APP_ID`: Firebase App ID do app Android (ex: `1:1234567890:android:abcdef...`).

iOS secrets (necessários para distribuir iOS via Firebase App Distribution):

- `APPLE_CERTIFICATE_BASE64`: o conteúdo base64 do arquivo `.p12` que contém o certificado de assinatura (p. ex. `exported_cert.p12`).
- `APPLE_CERTIFICATE_PASSWORD`: senha do arquivo `.p12` (se houver).
- `MOBILEPROVISION_BASE64`: o conteúdo base64 do provisioning profile (`.mobileprovision`) correspondente ao app.
- `FIREBASE_IOS_APP_ID`: Firebase App ID do app iOS (ex: `1:1234567890:ios:abcdef...`).

Como gerar os valores base64 localmente (macOS/Linux):

```bash
# certificado .p12 -> base64
base64 -i my_cert.p12 | tr -d '\n' > apple_cert_base64.txt

# provisioning profile -> base64
base64 -i my_profile.mobileprovision | tr -d '\n' > mobileprovision_base64.txt

# copie o conteúdo dos arquivos gerados para os respectivos secrets:
# APPLE_CERTIFICATE_BASE64, MOBILEPROVISION_BASE64
```

Observações:
- O job iOS usa `macos-latest` e importa o `.p12` para o keychain e instala o provisioning profile antes de rodar `flutter build ipa --export-method ad-hoc`.
- Dependendo da configuração do time/Apple Developer Account pode ser mais conveniente usar `fastlane match` ou App Store Connect API keys para gerenciamento de certificados — posso te ajudar a migrar para esse fluxo se preferir.
- Se preferir distribuir via TestFlight/App Store em vez do Firebase App Distribution, também posso adicionar essa etapa.

Como gerar o `FIREBASE_TOKEN` localmente:

```bash
# instale firebase-tools localmente (se ainda não tiver):
npm install -g firebase-tools

# faça login interativo e gere um token para CI:
firebase login:ci

# copie o token gerado e adicione como secreto `FIREBASE_TOKEN` no repo
```

Observações e próximos passos:

- A Action de `main` atualmente distribui somente o artefato Android (AAB). Para adicionar deploy iOS via Firebase App Distribution é necessário:
  - usar um runner `macos-latest`;
  - prover credenciais de assinatura (certificado e provisioning profile) ou usar `signing` automatizado (fastlane/cert/ sigh);
  - fornecer `FIREBASE_IOS_APP_ID` e ajustar o caminho/artefato (`.ipa`).
- Posso estender a pipeline para iOS se você fornecer as credenciais de assinatura e confirmar que deseja incluir distribuição iOS.
