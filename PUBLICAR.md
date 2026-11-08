# Como publicar o PetCadê

Guia rápido para a fase de testes (Android, iPhone e regras de segurança).
Todos os comandos são rodados na pasta do projeto, no PowerShell.

---

## 1. Preparar (uma vez só)

1. Instale o **Node.js LTS**: https://nodejs.org (próximo, próximo, concluir).
2. Instale as ferramentas do Firebase e entre com a sua conta Google:

   ```bash
   npm install -g firebase-tools
   firebase login
   ```

O projeto já está ligado ao Firebase `petcade` (arquivo `.firebaserc`).

---

## 2. Publicar as regras de segurança

Sempre que o arquivo `firestore.rules` mudar:

```bash
firebase deploy --only firestore:rules
```

> As regras exigem e-mail confirmado para publicar anúncios, avisar
> avistamentos e denunciar. Contas Google já vêm confirmadas.

---

## 3. Android (APK)

1. Aumente a versão em `pubspec.yaml` (o número depois do `+` sempre sobe):
   `version: 1.0.1+2`
2. Gere o APK:

   ```bash
   flutter build apk --release --split-per-abi
   ```

3. Use o arquivo `build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`.
4. Distribua:
   - **Firebase App Distribution** (recomendado): Firebase Console →
     *Lançamento e monitoramento* → *App Distribution* → enviar o APK →
     convidar os testadores por e-mail; ou
   - **WhatsApp / Google Drive**: mande o arquivo direto.

Ao instalar, o colega precisa permitir *"Instalar apps desconhecidos"* e,
se o Play Protect avisar, tocar em *Mais detalhes → Instalar mesmo assim*.

> O login com Google só funciona em APKs gerados neste computador (o SHA-1
> dele está no Firebase). Em outro computador, cadastre o SHA-1 de lá também.

---

## 4. iPhone (versão web)

1. Gere a versão web e publique no Firebase Hosting (grátis):

   ```bash
   flutter build web --release
   firebase deploy --only hosting
   ```

2. Mande este link para os colegas com iPhone:

   **https://petcade.firebaseapp.com**

   > Use este endereço (e não o `petcade.web.app`): no iPhone, o login com
   > Google funciona melhor no mesmo domínio do Firebase.

3. No iPhone: abrir o link no **Safari** → botão **Compartilhar** →
   **Adicionar à Tela de Início**. O PetCadê aparece com o ícone, em tela cheia.

Para atualizar, repita o passo 1: quem já usa recebe a versão nova ao abrir.

Diferenças da versão web: fotos são escolhidas pelo seletor do iPhone
(câmera ou galeria) e a localização pede permissão ao Safari.

---

## 5. Revisar denúncias

Com **3 denúncias** um anúncio sai das buscas e do mapa.

1. Firebase Console → *Firestore Database* → coleção **`denuncias`**:
   veja o motivo de cada denúncia (o campo `petId` diz qual anúncio).
2. Abra o anúncio em **`pets_perdidos`** e decida:
   - **Era golpe/falso:** exclua o documento do anúncio.
   - **Foi engano:** mude o campo **`denuncias`** para `0` — o anúncio volta
     a aparecer.

---

## 6. Testar as regras de segurança (opcional)

Os testes rodam no emulador oficial do Firebase (precisa de Java 17+):

```bash
cd test_regras
npm install
npm test
```
